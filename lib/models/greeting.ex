defmodule ZeroMQ.Greeting do
  defstruct signature: <<0xff, 0::8 * 8, 0x7f>>,
            major_version: 3,
            minor_version: 1,
            mechanism: "NULL",
            as_server: false,
            filler: <<0::31 * 8>>

  def parse(binary_greeting) do
    <<
      signature::binary-size(10),
      major_version, minor_version,
      mechanism::binary-size(20),
      as_server::binary-size(1),
      filler::binary-size(31),
    >> = binary_greeting

    %__MODULE__{
      signature: signature,
      major_version: major_version,
      minor_version: minor_version,
      mechanism: parse_mechanism(mechanism),
      as_server: parse_as_server(as_server),
      filler: filler,
    }
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
      greeting.major_version,
      greeting.minor_version,
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
end
