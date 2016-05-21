defmodule ElixirZeroMQ.FrameTest do
  use ExUnit.Case, async: true

  setup do
    {:ok,
      short_final_message: %ElixirZeroMQ.Message{
        body: short_text,
        more: false,
      },
      long_final_message: %ElixirZeroMQ.Message{
        body: loads_of_text,
        more: false,
      },
      short_message: %ElixirZeroMQ.Message{
        body: short_text,
        more: true,
      },
      long_message: %ElixirZeroMQ.Message{
        body: loads_of_text,
        more: true,
      },
      short_command: %ElixirZeroMQ.Command{
        name: "SHORTCOMMAND",
        data: short_text,
      },
      long_command: %ElixirZeroMQ.Command{
        name: "LONGCOMMAND",
        data: loads_of_text,
      },
    }
  end

  test "encode_command(short_command)" do
    short_command = %ElixirZeroMQ.Command{name: "SHORT_COMMAND", data: short_text}

    encoded_frame = ElixirZeroMQ.Frame.encode_command(short_command)

    binary_command = to_string(short_command)
    expected_encoding = <<0x04, byte_size(binary_command), binary_command::binary>>

    assert encoded_frame == expected_encoding
  end

  test "encode_command(long_command)" do
    long_command = %ElixirZeroMQ.Command{name: "LONG_COMMAND", data: loads_of_text}

    encoded_frame = ElixirZeroMQ.Frame.encode_command(long_command)

    binary_command = to_string(long_command)
    expected_encoding = <<0x06, byte_size(binary_command)::8 * 8, binary_command::binary>>

    assert encoded_frame == expected_encoding
  end

  test "encode_message(short_message)" do
    short_message = %ElixirZeroMQ.Message{body: short_text, more: true}

    encoded_frame = ElixirZeroMQ.Frame.encode_message(short_message)

    binary_message = to_string(short_message)
    expected_encoding = <<0x01, byte_size(binary_message), binary_message::binary>>

    assert encoded_frame == expected_encoding
  end

  test "encode_message(short_final_message)" do
    short_final_message = %ElixirZeroMQ.Message{body: short_text, more: false}

    encoded_frame = ElixirZeroMQ.Frame.encode_message(short_final_message)

    binary_message = to_string(short_final_message)
    expected_encoding = <<0x00, byte_size(binary_message), binary_message::binary>>

    assert encoded_frame == expected_encoding
  end

  test "encode_message(long_message)" do
    long_message = %ElixirZeroMQ.Message{body: loads_of_text, more: true}

    encoded_frame = ElixirZeroMQ.Frame.encode_message(long_message)

    binary_message = to_string(long_message)
    expected_encoding = <<0x03, byte_size(binary_message)::8 * 8, binary_message::binary>>

    assert encoded_frame == expected_encoding
  end

  test "encode_message(long_final_message)" do
    long_final_message = %ElixirZeroMQ.Message{body: loads_of_text, more: false}

    encoded_frame = ElixirZeroMQ.Frame.encode_message(long_final_message)

    binary_message = to_string(long_final_message)
    expected_encoding = <<0x02, byte_size(binary_message)::8 * 8, binary_message::binary>>

    assert encoded_frame == expected_encoding
  end

  test "parsing binary short messages", context do
    binary_message = ElixirZeroMQ.Frame.encode_message(context[:short_message])
    {flags, _size, frame_body} = ElixirZeroMQ.Frame.extract_flags_and_size(binary_message)
    struct_message = ElixirZeroMQ.Frame.parse(flags, frame_body)

    assert struct_message == context[:short_message]
  end

  test "parsing binary long messages", context do
    binary_message = ElixirZeroMQ.Frame.encode_message(context[:long_message])
    {flags, _size, frame_body} = ElixirZeroMQ.Frame.extract_flags_and_size(binary_message)
    struct_message = ElixirZeroMQ.Frame.parse(flags, frame_body)

    assert struct_message == context[:long_message]
  end

  test "parsing binary short final messages", context do
    binary_message = ElixirZeroMQ.Frame.encode_message(context[:short_final_message])
    {flags, _size, frame_body} = ElixirZeroMQ.Frame.extract_flags_and_size(binary_message)
    struct_message = ElixirZeroMQ.Frame.parse(flags, frame_body)

    assert struct_message == context[:short_final_message]
  end

  test "parsing binary long final messages", context do
    binary_message = ElixirZeroMQ.Frame.encode_message(context[:long_final_message])
    {flags, _size, frame_body} = ElixirZeroMQ.Frame.extract_flags_and_size(binary_message)
    struct_message = ElixirZeroMQ.Frame.parse(flags, frame_body)

    assert struct_message == context[:long_final_message]
  end

  test "parsing binary short commands", context do
    binary_command = ElixirZeroMQ.Frame.encode_command(context[:short_command])
    {flags, _size, frame_body} = ElixirZeroMQ.Frame.extract_flags_and_size(binary_command)
    struct_command = ElixirZeroMQ.Frame.parse(flags, frame_body)

    assert struct_command == context[:short_command]
  end

  test "parsing binary long commands", context do
    binary_command = ElixirZeroMQ.Frame.encode_command(context[:long_command])
    {flags, _size, frame_body} = ElixirZeroMQ.Frame.extract_flags_and_size(binary_command)
    struct_command = ElixirZeroMQ.Frame.parse(flags, frame_body)

    assert struct_command == context[:long_command]
  end

  defp short_text do
    "Here is some data under 255 bytes"
  end

  defp loads_of_text do
    """
    Sed posuere consectetur est at lobortis. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Nullam id dolor id nibh ultricies vehicula ut id elit. Nullam quis risus eget urna mollis ornare vel eu leo. Cras mattis consectetur purus sit amet fermentum.

    Cras mattis consectetur purus sit amet fermentum. Aenean lacinia bibendum nulla sed consectetur. Curabitur blandit tempus porttitor. Donec sed odio dui. Curabitur blandit tempus porttitor. Vestibulum id ligula porta felis euismod semper. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.

    Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Maecenas sed diam eget risus varius blandit sit amet non magna.

    Curabitur blandit tempus porttitor. Nullam quis risus eget urna mollis ornare vel eu leo. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Cras mattis consectetur purus sit amet fermentum. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Nullam quis risus eget urna mollis ornare vel eu leo.
    """
  end
end
