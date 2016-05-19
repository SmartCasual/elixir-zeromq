defmodule ElixirZeroMQ.Greeting do
  defstruct signature: <<0xff,0::size(8)-unit(8),0x7f>>,
            version: "3.1",
            mechanism: "NULL",
            as_server: false,
            filler: <<0::size(31)-unit(8)>>

  def parse(binary_greeting) do
    <<
      signature::size(10)-unit(8)-binary,
      version::size(2)-unit(8)-binary,
      mechanism::size(20)-unit(8)-binary,
      as_server::size(1)-unit(8)-binary,
      filler::size(31)-unit(8)-binary
    >> = binary_greeting

    %__MODULE__{
      signature: signature,
      version: parse_version(version),
      mechanism: parse_mechanism(mechanism),
      as_server: parse_as_server(as_server),
      filler: filler
    }
  end

  defp parse_version(version) do
    <<major::size(1)-unit(8), minor::size(1)-unit(8)>> = version
    "#{to_string(major)}.#{to_string(minor)}"
  end

  defp parse_mechanism(mechanism) do
    String.rstrip(mechanism, 0x00)
  end

  defp parse_as_server(as_server) do
    as_server == <<1>>
  end
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
