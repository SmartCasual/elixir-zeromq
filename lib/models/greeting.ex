defmodule ElixirZeroMQ.Greeting do
  defstruct signature: <<0xff,0::size(8)-unit(8),0x7f>>,
            version: "3.1",
            mechanism: "NULL",
            as_server: false,
            filler: <<0::size(31)-unit(8)>>
end

defimpl String.Chars, for: ElixirZeroMQ.Greeting do
  def to_string(greeting) do
    [
      greeting.signature,
      version(greeting),
      mechanism(greeting),
      as_server(greeting),
      greeting.filler,
    ] |> IO.iodata_to_binary
  end

  defp mechanism(greeting) do
    mechanism_string = greeting.mechanism
    mechanism_length = byte_size(mechanism_string)
    padding_length = 20 - mechanism_length

    [mechanism_string, <<0::unit(8)-size(padding_length)>>]
  end

  defp as_server(greeting) do
    if greeting.as_server, do: <<1>>, else: <<0>>
  end

  defp version(greeting) do
    [major, minor] = String.split(greeting.version, ".")

    [String.to_integer(major), String.to_integer(minor)]
      |> IO.iodata_to_binary
  end
end
