defmodule ZeroMQ.Connection do
  @moduledoc """
  A GenServer which handles the back and forth of
  a ZeroMQ connection, including signature exchange, security etc.
  """

  use GenServer

  @doc """
  Starts the connection with no security or confidentiality by default.
  """
  def start_link(callbacks) do
    callbacks = Map.put_new(callbacks,
      :security_mechanism, &ZeroMQ.NullSecurityMechanism.process_command/1
    )
    GenServer.start_link(__MODULE__, callbacks, [])
  end

  @doc """
  Adds the provided binary blob to the current stream and processes resulting
  complete frames using the callbacks provided during initialization.

  Processes commands via `callbacks[:security_mechanism].(frame)`.
  Delivers messages via `callbacks[:message_delivery].(frame)`.

  Returns `:ok`.
  """
  def notify(connection, raw_binary) do
    GenServer.call(connection, {:notify, raw_binary})
  end

  @doc """
  Encodes the provided message into a frame and sends it via the provided peer
  delivery callback.

  Returns `:ok`.
  """
  def transmit_message(connection, message) do
    GenServer.call(connection, {:transmit_message, message})
  end

  def init(callbacks) do
    callbacks[:peer_delivery].(to_string(%ZeroMQ.Greeting{}))

    {:ok, splitter} = ZeroMQ.FrameSplitter.start_link
    {:ok, {callbacks, splitter, :preauth}}
  end

  def handle_call({:transmit_message, message}, _from, {callbacks, splitter, phase}) do
    if phase == :ready do
      message_frame = ZeroMQ.Frame.encode_message(message)
      callbacks[:peer_delivery].(message_frame)
    end

    {:reply, :ok, {callbacks, splitter, phase}}
  end

  def handle_call({:notify, raw_binary}, _from, {callbacks, splitter, phase}) do
    {:ok, _frames_available} = ZeroMQ.FrameSplitter.add_binary(splitter, raw_binary)
    {:ok, frames} = ZeroMQ.FrameSplitter.fetch(splitter)

    new_phase = process_next_frame(frames, phase, callbacks)
    state = {callbacks, splitter, new_phase}

    case new_phase do
      {:abort, reason} ->
        {:stop, "Closing connection", {:closed, reason}, state}
      _ ->
        {:reply, :ok, state}
    end
  end

  defp process_next_frame([], new_phase, _) do
    new_phase
  end
  defp process_next_frame([{flags, frame_body} | remainder], current_phase, callbacks) do
    frame = ZeroMQ.Frame.parse(flags, frame_body)

    frame_is_command = flags[:command]

    new_phase = if frame_is_command do
      process_command(frame, current_phase, callbacks)
    else
      current_phase
    end

    case new_phase do
      :ready when not frame_is_command ->
        callbacks[:message_delivery].(frame)
      :abort ->
        callbacks[:connection_abort].(frame)
      _ -> nil
    end

    process_next_frame(remainder, new_phase, callbacks)
  end

  defp process_command(frame, current_phase, callbacks) do
    case callbacks[:security_mechanism].(frame) do
      {:ok, :complete} -> :ready
      {:ok, :incomplete} -> current_phase
      {:error, reason} ->
        error_command = %ZeroMQ.Command{name: "ERROR", data: reason}
        error_frame = ZeroMQ.Frame.encode_command(error_command)
        callbacks[:peer_delivery].(error_frame)

        {:abort, reason}
    end
  end
end
