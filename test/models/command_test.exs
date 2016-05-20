defmodule ElixirZeroMQ.CommandTest do
  use ExUnit.Case, async: true

  test "to_string explodes without binary blobs" do
    assert_raise ArgumentError, fn ->
      to_string %ElixirZeroMQ.Command{name: 123}
    end

    assert_raise ArgumentError, fn ->
      to_string %ElixirZeroMQ.Command{data: 123}
    end
  end

  setup do
    {:ok,
      short_command: %ElixirZeroMQ.Command{
        name: "SHORTCOMMAND",
        data: "Here is some data under 255 bytes",
      },
      long_command: %ElixirZeroMQ.Command{
        name: "LONGCOMMAND",
        data: loads_of_text,
      },
    }
  end

  test "encodes the command name with a size", context do
    assert parsed_command(context[:short_command])[:name] == "SHORTCOMMAND"
    assert parsed_command(context[:short_command])[:name_size] == 12

    assert parsed_command(context[:long_command])[:name] == "LONGCOMMAND"
    assert parsed_command(context[:long_command])[:name_size] == 11
  end

  test "marks the command as either long or short", context do
    assert parsed_command(context[:short_command])[:command_size_type] == :short
    assert parsed_command(context[:long_command])[:command_size_type] == :long
  end

  test "encodes the command data", context do
    assert parsed_command(context[:short_command])[:data] == context[:short_command].data
    assert parsed_command(context[:long_command])[:data] == context[:long_command].data
  end

  test "parsing binary short commands", context do
    binary_command = to_string(context[:short_command])
    struct_command = ElixirZeroMQ.Command.parse(binary_command)

    assert struct_command == context[:short_command]
  end

  test "parsing binary long commands", context do
    binary_command = to_string(context[:long_command])
    struct_command = ElixirZeroMQ.Command.parse(binary_command)

    assert struct_command == context[:long_command]
  end

  defp parsed_command(command) do
    case to_string(command) do
      <<
        0x04,
        size::1 * 8,
        name_size::1 * 8,
        name::binary-size(name_size),
        data::binary,
      >> ->
        data_size = size - name_size - 1
        <<data::binary-size(data_size)>> = data

        %{
          command_size_type: :short,
          command_size: size,
          name_size: name_size,
          name: name,
          data: data,
        }

      <<
        0x06,
        size::8 * 8,
        name_size::1 * 8,
        name::binary-size(name_size),
        data::binary,
      >> ->
        data_size = size - name_size - 1
        <<data::binary-size(data_size)>> = data

        %{
          command_size_type: :long,
          command_size: size,
          name_size: name_size,
          name: name,
          data: data,
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
