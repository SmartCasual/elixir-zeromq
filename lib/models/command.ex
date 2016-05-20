defmodule ElixirZeroMQ.Command do
  defstruct name: nil,
            data: nil

  def parse(<<0x04,remainder::binary>>) do
    <<
      command_size::1 * 8,
      name_size::1 * 8,
      name::binary-size(name_size),
      data::binary,
    >> = remainder

    data = validate_data_length(data, command_size, name_size)

    %__MODULE__{
      name: name,
      data: data,
    }
  end

  def parse(<<0x06,remainder::binary>>) do
    <<
      command_size::8 * 8,
      name_size::1 * 8,
      name::binary-size(name_size),
      data::binary,
    >> = remainder

    data = validate_data_length(data, command_size, name_size)

    %__MODULE__{
      name: name,
      data: data,
    }
  end

  defp validate_data_length(data, size, name_size) do
    data_size = size - name_size - 1
    <<data::binary-size(data_size)>> = data

    data
  end
end

defimpl String.Chars, for: ElixirZeroMQ.Command do
  def to_string(command) do
    unless is_binary(command.name) and is_binary(command.data) do
      raise ArgumentError, message: "Commands require binary names and data blobs"
    end

    name_string = command.name
    name_size = byte_size(name_string)
    name_size = <<name_size::1 * 8>>

    name = <<name_size::binary, name_string::binary>>
    body = <<name::binary, command.data::binary>>

    body_size = byte_size(body)
    if body_size > 255 do
      body_size = <<0x06, body_size::8 * 8>>
    else
      body_size = <<0x04, body_size::1 * 8>>
    end

    <<body_size::binary, body::binary>>
  end
end
