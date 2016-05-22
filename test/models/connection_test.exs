defmodule ZeroMQ.ConnectionTest do
  use ExUnit.Case, async: true

  setup do
    test_process = self()

    mock_security_mechanism_callback = fn command ->
      send test_process, {:processed_command, command}
    end

    mock_delivery_callback = fn message ->
      send test_process, {:delivered_message, message}
    end

    {:ok, connection} = ZeroMQ.Connection.start_link(%{
      message_delivery: mock_delivery_callback,
      security_mechanism: mock_security_mechanism_callback
    })

    {:ok,
      connection: connection,
      delivery_callback: mock_delivery_callback,
      security_mechanism_callback: mock_security_mechanism_callback,
      command: %ZeroMQ.Command{name: "SHORTCOMMAND", data: "Short text"},
      message: %ZeroMQ.Message{body: "Short message"},
    }
  end

  test "commands are processed by the provided security mechanism callback", context do
    command = context[:command]
    command_frame = ZeroMQ.Frame.encode_command(command)

    ZeroMQ.Connection.notify(context[:connection], command_frame)

    assert_received {:processed_command, ^command}
  end

  test "messages are processed by the provided security mechanism callback", context do
    message = context[:message]
    message_frame = ZeroMQ.Frame.encode_message(message)

    ZeroMQ.Connection.notify(context[:connection], message_frame)

    assert_received {:delivered_message, ^message}
  end

  test "partial data is processed as it completes", context do
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
    message = context[:message]
    message_frame = ZeroMQ.Frame.encode_message(message)

    command = context[:command]
    command_frame = ZeroMQ.Frame.encode_command(command)

    combined_frames = message_frame <> command_frame
    ZeroMQ.Connection.notify(context[:connection], combined_frames)

    assert_received {:delivered_message, ^message}
    assert_received {:processed_command, ^command}
  end
end
