defmodule ZeroMQ.ConnectionTest do
  use ExUnit.Case, async: true

  setup do
    test_process = self()

    mock_security_mechanism_callback = fn command ->
      send test_process, {:processed_command, command}
      {:ok, :complete}
    end

    mock_delivery_callback = fn message ->
      send test_process, {:delivered_message, message}
    end

    mock_peer_callback = fn frame_blob ->
      send test_process, {:sent_to_peer, frame_blob}
    end

    mock_abort_callback = fn frame ->
      send test_process, {:disconnected, frame}
    end

    {:ok, connection} = ZeroMQ.Connection.start_link(%{
      message_delivery: mock_delivery_callback,
      security_mechanism: mock_security_mechanism_callback,
      connection_abort: mock_abort_callback,
      peer_delivery: mock_peer_callback,
    })

    {:ok,
      connection: connection,
      delivery_callback: mock_delivery_callback,
      security_mechanism_callback: mock_security_mechanism_callback,
      abort_callback: mock_abort_callback,
      peer_delivery_callback: mock_peer_callback,
      command: %ZeroMQ.Command{name: "SHORTCOMMAND", data: "Short text"},
      message: %ZeroMQ.Message{body: "Short message"},
      valid_security_command: %ZeroMQ.Command{name: "VALIDCREDS", data: "letmein"},
      simple_security_callback: fn command ->
        if command.name == "VALIDCREDS" and command.data == "letmein" do
          {:ok, :complete}
        else
          {:error, "Incorrect credentials"}
        end
      end,
      failing_security_callback: fn _command -> {:error, "Denied!"} end,
    }
  end

  test "commands are processed by the provided security mechanism callback", context do
    command = context[:command]
    command_frame = ZeroMQ.Frame.encode_command(command)

    ZeroMQ.Connection.notify(context[:connection], command_frame)

    assert_received {:processed_command, ^command}
  end

  test "messages are processed by the provided security mechanism callback", context do
    command_frame = ZeroMQ.Frame.encode_command(context[:command])
    ZeroMQ.Connection.notify(context[:connection], command_frame)

    message = context[:message]
    message_frame = ZeroMQ.Frame.encode_message(message)

    ZeroMQ.Connection.notify(context[:connection], message_frame)

    assert_received {:delivered_message, ^message}
  end

  test "partial data is processed as it completes", context do
    command_frame = ZeroMQ.Frame.encode_command(context[:command])
    ZeroMQ.Connection.notify(context[:connection], command_frame)

    message = context[:message]
    message_frame = ZeroMQ.Frame.encode_message(message)

    half_frame_length = div(byte_size(message_frame), 2)
    {first_half, second_half} = String.split_at(message_frame, half_frame_length)

    ZeroMQ.Connection.notify(context[:connection], first_half)
    refute_received {:delivered_message, ^first_half}

    ZeroMQ.Connection.notify(context[:connection], second_half)
    assert_received {:delivered_message, ^message}
  end

  test "multiple messages are processed together", context do
    command_frame = ZeroMQ.Frame.encode_command(context[:command])
    ZeroMQ.Connection.notify(context[:connection], command_frame)

    message = context[:message]
    message_frame = ZeroMQ.Frame.encode_message(message)

    command = context[:command]
    command_frame = ZeroMQ.Frame.encode_command(command)

    combined_frames = message_frame <> command_frame
    ZeroMQ.Connection.notify(context[:connection], combined_frames)

    assert_received {:delivered_message, ^message}
    assert_received {:processed_command, ^command}
  end

  test "will only receive messages after security has passed", context do
    {:ok, connection} = ZeroMQ.Connection.start_link(%{
      message_delivery: context[:delivery_callback],
      security_mechanism: context[:simple_security_callback],
    })

    message = context[:message]
    message_frame = ZeroMQ.Frame.encode_message(message)

    ZeroMQ.Connection.notify(connection, message_frame)

    refute_received {:delivered_message, ^message}

    security_frame = ZeroMQ.Frame.encode_command(context[:valid_security_command])
    ZeroMQ.Connection.notify(connection, security_frame)

    ZeroMQ.Connection.notify(connection, message_frame)
    assert_received {:delivered_message, ^message}
  end

  test "failing security sends an error command to the peer and aborts", context do
    {:ok, connection} = ZeroMQ.Connection.start_link(%{
      message_delivery: context[:delivery_callback],
      security_mechanism: context[:failing_security_callback],
      connection_abort: context[:abort_callback],
      peer_delivery: context[:peer_delivery_callback],
    })

    Process.unlink(connection)

    security_frame = ZeroMQ.Frame.encode_command(context[:command])

    ZeroMQ.Connection.notify(connection, security_frame)

    refute Process.alive?(connection)

    error_command = %ZeroMQ.Command{name: "ERROR", data: "Denied!"}
    error_frame = ZeroMQ.Frame.encode_command(error_command)
    assert_received {:sent_to_peer, ^error_frame}
  end

  test "transmits messages after security has passed", context do
    {:ok, connection} = ZeroMQ.Connection.start_link(%{
      peer_delivery: context[:peer_delivery_callback],
      security_mechanism: context[:simple_security_callback],
    })

    message = context[:message]
    message_frame = ZeroMQ.Frame.encode_message(message)

    ZeroMQ.Connection.transmit_message(connection, message)

    refute_received {:sent_to_peer, ^message_frame}

    security_frame = ZeroMQ.Frame.encode_command(context[:valid_security_command])
    ZeroMQ.Connection.notify(connection, security_frame)

    ZeroMQ.Connection.transmit_message(connection, message)
    assert_received {:sent_to_peer, ^message_frame}
  end
end
