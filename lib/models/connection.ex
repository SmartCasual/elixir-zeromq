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

  Processes commands via `security_mechanism.process_command(frame)`.
  Delivers messages via `delivery_callback.(frame)`.

  Returns `:ok`.
  """
  def notify(connection, raw_binary) do
    GenServer.call(connection, {:notify, raw_binary})
  end

  def init(callbacks) do
    {:ok, splitter} = ZeroMQ.FrameSplitter.start_link
    {:ok, {callbacks, splitter, :preauth}}
  end

  def handle_call({:notify, raw_binary}, _from, {callbacks, splitter, phase}) do
    {:ok, _frames_available} = ZeroMQ.FrameSplitter.add_binary(splitter, raw_binary)
    {:ok, frames} = ZeroMQ.FrameSplitter.fetch(splitter)

    new_phase = process_next_frame(frames, phase, callbacks)

    {:reply, :ok, {callbacks, splitter, new_phase}}
  end

  defp process_next_frame([], new_phase, _) do
    new_phase
  end
  defp process_next_frame([{flags, frame_body} | remainder], current_phase, callbacks) do
    frame = ZeroMQ.Frame.parse(flags, frame_body)

    frame_is_command = flags[:command]

    new_phase = if frame_is_command do
      process_command(frame, current_phase, callbacks[:security_mechanism])
    else
      current_phase
    end

    case new_phase do
      :ready when not frame_is_command ->
        callbacks[:message_delivery].(frame)
      :abort ->
        callbacks[:abort].()
        ZeroMQ.Connection.stop(self())
      _ -> nil
    end

    process_next_frame(remainder, new_phase, callbacks)
  end

  defp process_command(frame, current_phase, security_mechanism) do
    case security_mechanism.(frame) do
      {:ok, :complete} -> :ready
      {:ok, :incomplete} -> current_phase
      {:error} -> :abort
    end
  end
end
