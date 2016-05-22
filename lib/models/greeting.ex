defmodule ZeroMQ.Greeting do
  defstruct signature: <<0xff, 0::8 * 8, 0x7f>>,
            version: "3.1",
            mechanism: "NULL",
            as_server: false,
            filler: <<0::31 * 8>>

  def parse(binary_greeting) do
    <<
      signature::binary-size(10),
      version::binary-size(2),
      mechanism::binary-size(20),
      as_server::binary-size(1),
      filler::binary-size(31),
    >> = binary_greeting

    %__MODULE__{
      signature: signature,
      version: parse_version(version),
      mechanism: parse_mechanism(mechanism),
      as_server: parse_as_server(as_server),
      filler: filler,
    }
  end

  defp parse_version(version) do
    <<major::integer, minor::integer>> = version
    "#{to_string(major)}.#{to_string(minor)}"
  end

  defp parse_mechanism(mechanism) do
    String.rstrip(mechanism, 0x00)
  end

  defp parse_as_server(as_server) do
    as_server == <<1>>
  end
end

defimpl String.Chars, for: ZeroMQ.Greeting do
  def to_string(greeting) do
    <<
      greeting.signature::binary,
      version(greeting)::binary,
      mechanism(greeting)::binary,
      as_server(greeting)::binary,
      greeting.filler::binary,
    >>
  end

  defp mechanism(greeting) do
    mechanism_string = greeting.mechanism
    mechanism_length = byte_size(mechanism_string)
    padding_length = 20 - mechanism_length

    <<mechanism_string::binary, <<0::unit(8)-size(padding_length)>> >>
  end

  defp as_server(greeting) do
    if greeting.as_server, do: <<1>>, else: <<0>>
  end

  defp version(greeting) do
    [major, minor] = String.split(greeting.version, ".")

    <<String.to_integer(major), String.to_integer(minor)>>
  end
end
