defmodule ZeroMQ.HeartbeatTest do
  use ExUnit.Case, async: true

  setup do
    test_process = self()

    mock_peer_callback = fn frame_blob ->
      send test_process, {:sent_to_peer, frame_blob}
    end

    mock_abort_callback = fn frame ->
      send test_process, {:disconnected, frame}
    end

    {:ok, heartbeat} = ZeroMQ.Heartbeat.start_link(%{
      connection_abort: mock_abort_callback,
      peer_delivery: mock_peer_callback,
    })

    standard_timeout_ms = 100
    standard_timeout_tenths = 1

    {:ok,
      heartbeat: heartbeat,
      abort_callback: mock_abort_callback,
      peer_delivery_callback: mock_peer_callback,
      standard_timeout_ms: standard_timeout_ms,
      ping_command: %ZeroMQ.Command{
        name: "PING",
        data: <<standard_timeout_tenths::2 * 8, "Some context">>
      },
    }
  end

  test "responds to a PING with a PONG", context do
    ping = %ZeroMQ.Command{name: "PING", data: <<5::2 * 8, "Some context">>}
    ZeroMQ.Heartbeat.ping_received(context[:heartbeat], ping)

    pong = %ZeroMQ.Command{name: "PONG", data: "Some context"}
    pong_frame = ZeroMQ.Frame.encode_command(pong)

    assert_received {:sent_to_peer, ^pong_frame}
  end

  test "sets the ping timeout to the TTL of the received PING command", context do
    ZeroMQ.Heartbeat.ping_received(context[:heartbeat], context[:ping_command])

    state = get_state(context[:heartbeat])
    timeout_ms = state.ping_timeout
      |> Process.read_timer

    assert timeout_ms == context[:standard_timeout_ms]
  end

  test "resets send-timer to 10 seconds when traffic is received", context do
    ZeroMQ.Heartbeat.traffic_received(context[:heartbeat])

    state = get_state(context[:heartbeat])
    send_timer_ms = state.send_timer
      |> Process.read_timer

    assert send_timer_ms == 10_000
  end

  test "cancels ping timeout when traffic is received", context do
    ZeroMQ.Heartbeat.ping_received(context[:heartbeat], context[:ping_command])
    ZeroMQ.Heartbeat.traffic_received(context[:heartbeat])

    state = get_state(context[:heartbeat])
    assert state.ping_timeout == nil
  end

  test "a :ping_timeout message sends a timeout to the peer and aborts the connection", context do
    send(context[:heartbeat], :ping_timeout)

    error_command = %ZeroMQ.Command{name: "ERROR", data: "Ping timeout"}
    assert_receive {:disconnected, ^error_command}

    error_frame = ZeroMQ.Frame.encode_command(error_command)
    assert_receive {:sent_to_peer, ^error_frame}
  end

  test "a :send_ping message sends a PING with TTL of 30 seconds (in tenths of seconds)", context do
    send(context[:heartbeat], :send_ping)

    timeout_tenths = 300
    ping_command = %ZeroMQ.Command{name: "PING", data: <<timeout_tenths>>}
    ping_frame = ZeroMQ.Frame.encode_command(ping_command)

    assert_receive {:sent_to_peer, ^ping_frame}
  end

  test "a :send_ping message starts a 30 second ping timeout", context do
    send(context[:heartbeat], :send_ping)

    state = get_state(context[:heartbeat])
    timeout_ms = state.ping_timeout
      |> Process.read_timer

    assert timeout_ms == 30_000
  end

  defp get_state(heartbeat) do
    {
      :status, _, _,
      [_, _, _, _, [header: _, data: _, data: [{'State', state}]]]
    } = :sys.get_status(heartbeat)

    state
  end
end
