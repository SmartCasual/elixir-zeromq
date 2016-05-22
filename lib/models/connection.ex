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
    {:ok, {callbacks, splitter}}
  end

  def handle_call({:notify, raw_binary}, _from, {callbacks, splitter}) do
    {:ok, _frames_available} = ZeroMQ.FrameSplitter.add_binary(splitter, raw_binary)
    {:ok, frames} = ZeroMQ.FrameSplitter.fetch(splitter)

    Enum.each(frames, fn {flags, frame_body} ->
      frame = ZeroMQ.Frame.parse(flags, frame_body)

      if flags[:command] do
        callbacks[:security_mechanism].(frame)
      else
        callbacks[:message_delivery].(frame)
      end
    end)

    {:reply, :ok, {callbacks, splitter}}
  end
end
