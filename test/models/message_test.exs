defmodule ElixirZeroMQ.MessageTest do
  use ExUnit.Case, async: true

  test "to_string explodes without binary blobs" do
    assert_raise ArgumentError, fn ->
      to_string %ElixirZeroMQ.Message{body: 123}
    end
  end

  setup do
    {:ok,
      short_final_message: %ElixirZeroMQ.Message{
        body: "Here is some data under 255 bytes",
        more: false,
      },
      long_final_message: %ElixirZeroMQ.Message{
        body: loads_of_text,
        more: false,
      },
      short_message: %ElixirZeroMQ.Message{
        body: "Here is some data under 255 bytes",
        more: true,
      },
      long_message: %ElixirZeroMQ.Message{
        body: loads_of_text,
        more: true,
      },
    }
  end

  test "encodes the message body with a size", context do
    assert parsed_message(context[:short_message])[:body] == context[:short_message].body
    assert parsed_message(context[:short_message])[:message_size] == 33

    assert parsed_message(context[:long_message])[:body] == loads_of_text
    assert parsed_message(context[:long_message])[:message_size] == 1365
  end

  test "marks the message as either long or short", context do
    assert parsed_message(context[:short_message])[:message_size_type] == :short
    assert parsed_message(context[:long_message])[:message_size_type] == :long
  end

  test "parsing binary short messages", context do
    binary_message = to_string(context[:short_message])
    struct_message = ElixirZeroMQ.Message.parse(binary_message)

    assert struct_message == context[:short_message]
  end

  test "parsing binary long messages", context do
    binary_message = to_string(context[:long_message])
    struct_message = ElixirZeroMQ.Message.parse(binary_message)

    assert struct_message == context[:long_message]
  end

  test "parsing binary short final messages", context do
    binary_message = to_string(context[:short_final_message])
    struct_message = ElixirZeroMQ.Message.parse(binary_message)

    assert struct_message == context[:short_final_message]
  end

  test "parsing binary long final messages", context do
    binary_message = to_string(context[:long_final_message])
    struct_message = ElixirZeroMQ.Message.parse(binary_message)

    assert struct_message == context[:long_final_message]
  end

  defp parsed_message(message) do
    case to_string(message) do
      <<
        0x00,
        size::1 * 8,
        body::binary-size(size),
      >> ->
        %{
          message_size_type: :short,
          message_size: size,
          body: body,
          more: false,
        }

      <<
        0x01,
        size::1 * 8,
        body::binary-size(size),
      >> ->
        %{
          message_size_type: :short,
          message_size: size,
          body: body,
          more: true,
        }

      <<
        0x02,
        size::8 * 8,
        body::binary-size(size),
      >> ->
        %{
          message_size_type: :long,
          message_size: size,
          body: body,
          more: false,
        }

      <<
        0x03,
        size::8 * 8,
        body::binary-size(size),
      >> ->
        %{
          message_size_type: :long,
          message_size: size,
          body: body,
          more: true,
        }
    end
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
