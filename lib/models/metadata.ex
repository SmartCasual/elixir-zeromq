defmodule ZeroMQ.Metadata do
  def encode(metadata) do
    sorted_keys = Map.keys(metadata) |> Enum.sort

    Enum.reduce(sorted_keys, [], fn(key, list) ->
      value = metadata[key]

      unless is_binary(key) and is_binary(value) do
        error = "Metadata keys and values must be binary blobs (or strings)"
        raise ArgumentError, message: error
      end

      list ++ [byte_size(key), key, <<byte_size(value)::4 * 8>>, value]
    end) |> IO.iodata_to_binary
  end

  def parse(binary) do
    parse(%{}, binary)
  end
  def parse(map, <<>>) do
    map
  end
  def parse(map, binary) do
    <<
      key_size, key::binary-size(key_size),
      value_size::4 * 8, value::binary-size(value_size),
      remainder::binary
    >> = binary

    Map.put(map, key, value)
      |> parse(remainder)
  end
end
