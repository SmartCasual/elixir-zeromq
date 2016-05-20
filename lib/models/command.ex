defmodule ElixirZeroMQ.Command do
  defstruct name: nil,
            data: nil

  def parse(<<name_size::1 * 8, name::binary-size(name_size), data::binary>>) do
    %__MODULE__{
      name: name,
      data: data,
    }
  end
end

defimpl String.Chars, for: ElixirZeroMQ.Command do
  def to_string(command) do
    unless is_binary(command.name) and is_binary(command.data) do
      raise ArgumentError, message: "Commands require binary names and data blobs"
    end

    <<
      byte_size(command.name)::1 * 8,
      command.name::binary,
      command.data::binary,
    >>
  end
end
