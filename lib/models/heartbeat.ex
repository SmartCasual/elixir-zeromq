defmodule ZeroMQ.Heartbeat do
  @moduledoc """
  A GenServer which monitors connection traffic for signs of life,
  aborting the connection if it appears to be stale.
  """

  use GenServer

  @doc """
  Starts a heartbeat monitor with peer delivery and abort callbacks so action
  can be taken if PINGs are received or the connection times out.
  """
  def start_link(callbacks) do
    GenServer.start_link(__MODULE__, callbacks, [])
  end

  @doc """
  1. Replies to the peer with an appropriate PONG command.
  2. Sets a timer to abort the connection if traffic is not received in the meantime.

  Returns `:ok`.
  """
  def ping_received(heartbeat, ping_command) do
    GenServer.call(heartbeat, {:ping_received, ping_command})
  end

  @doc """
  1. Resets send-timer for the next PING command.
  2. Clears current ping timeouts.
  """
  def traffic_received(heartbeat) do
    GenServer.call(heartbeat, :traffic_received)
  end

  def init(callbacks) do
    state = %ZeroMQ.HeartbeatState{callbacks: callbacks}
    {:ok, state}
  end

  def handle_call({:ping_received, ping_command}, _from, state) do
    <<ttl::2 * 8, context::binary>> = ping_command.data

    pong_command = %ZeroMQ.Command{
      name: "PONG",
      data: context,
    }
    pong_frame = ZeroMQ.Frame.encode_command(pong_command)
    state.callbacks[:peer_delivery].(pong_frame)

    new_timeout = state.ping_timeout || Process.send_after(self(), :ping_timeout, ttl * 100)

    {:reply, :ok, %{state | ping_timeout: new_timeout}}
  end

  def handle_call(:traffic_received, _from, state) do
    # Reset send-timer
    if state.send_timer do
      Process.cancel_timer(state.send_timer)
    end
    new_send_timer = Process.send_after(self(), :send_ping, 10_000)

    # Clear ping timeouts
    if state.ping_timeout do
      Process.cancel_timer(state.ping_timeout)
    end

    {:reply, :ok, %{state | send_timer: new_send_timer, ping_timeout: nil}}
  end

  def handle_info(:ping_timeout, state) do
    error_command = %ZeroMQ.Command{name: "ERROR", data: "Ping timeout"}
    state.callbacks[:connection_abort].(error_command)

    error_frame = ZeroMQ.Frame.encode_command(error_command)
    state.callbacks[:peer_delivery].(error_frame)

    {:noreply, state}
  end

  @standard_timeout_ms 30_000
  def handle_info(:send_ping, state) do
    timeout_tenths = div(@standard_timeout_ms, 100)

    ping_command = %ZeroMQ.Command{name: "PING", data: <<timeout_tenths>>}
    ping_frame = ZeroMQ.Frame.encode_command(ping_command)
    state.callbacks[:peer_delivery].(ping_frame)

    new_timeout = state.ping_timeout || Process.send_after(
      self(),
      :ping_timeout,
      @standard_timeout_ms
    )

    {:noreply, %{state | ping_timeout: new_timeout}}
  end
end
