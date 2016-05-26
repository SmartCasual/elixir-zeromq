defmodule ZeroMQ.Connection do
  @moduledoc """
  A GenServer which handles the back and forth of
  a ZeroMQ connection, including signature exchange, security etc.
  """

  use GenServer

  @doc """
  Starts the connection with no security or confidentiality by default.
  """
  def start_link(callbacks, greeting) do
    GenServer.start_link(__MODULE__, {callbacks, greeting}, [])
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

  def init({callbacks, greeting}) do
    callbacks[:peer_delivery].(to_string(greeting))

    {:ok, splitter} = ZeroMQ.FrameSplitter.start_link
    {:ok, {callbacks, splitter, :pregreets}}
  end

  def handle_call({:transmit_message, message}, _from, {callbacks, splitter, phase}) do
    if phase == :ready do
      message_frame = ZeroMQ.Frame.encode_message(message)
      callbacks[:peer_delivery].(message_frame)
    end

    {:reply, :ok, {callbacks, splitter, phase}}
  end

  def handle_call({:notify, raw_binary}, _from, {callbacks, splitter, phase}) do
    case phase do
      :pregreets ->
        process_greeting(raw_binary, callbacks, splitter, phase)
      _ ->
        process_frame(raw_binary, callbacks, splitter, phase)
    end
  end

  defp process_greeting(raw_binary, callbacks, splitter, phase) do
    greeting = ZeroMQ.Greeting.parse(raw_binary)

    failure_reason = cond do
      greeting.major_version != 3 ->
        "This peer only supports ZeroMQ 3.x"
      greeting.mechanism != "NULL" ->
        "This peer only supports the NULL security mechanism"
      greeting.as_server != false ->
        "The as-server flag must be `false` when using the NULL security mechanism"
      true ->
        nil
    end

    if failure_reason do
      abort_connection(failure_reason, callbacks[:peer_delivery])
      {:stop, "Closing connection", {:closed, failure_reason}, {callbacks, splitter, phase}}
    else
      {:reply, :ok, {callbacks, splitter, :handshake}}
    end
  end

  defp process_frame(raw_binary, callbacks, splitter, phase) do
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

  defp process_command(command, current_phase, callbacks) do
    case callbacks[:security_mechanism].(command) do
      {:ok, :complete} -> :ready
      {:ok, :incomplete} -> current_phase
      {:error, reason} ->
        abort_connection(reason, callbacks[:peer_delivery])
        {:abort, reason}
    end
  end

  defp abort_connection(reason, peer_delivery) do
    error_command = %ZeroMQ.Command{name: "ERROR", data: reason}
    error_frame = ZeroMQ.Frame.encode_command(error_command)
    peer_delivery.(error_frame)
  end
end
