defmodule ElixirZeroMQ.Frame do
  defstruct body: nil,
            command: false,
            long: false,
            more: false

  def parse(flags, body) do
    if flags[:command] do
      ElixirZeroMQ.Command.parse(body)
    else
      %ElixirZeroMQ.Message{
        body: body,
        more: flags[:more],
      }
    end
  end

  use Bitwise
  @more_flag 0b001
  @long_flag 0b010
  @command_flag 0b100

  @doc """
  Extracts flags map and body size from a (possible incomplete)
  frame blob.

  Returns `{flags_map, size, remainder}` if complete enough to
  parse, otherwise returns `:error`.
  """
  def extract_flags_and_size(<<flags_byte, blob::binary>>) do
    flags = parse_flags(flags_byte)

    if flags[:long] do
      case blob do
        <<size::8 * 8, remainder::binary>> ->
          {flags, size, remainder}
        _ ->
          :error
      end
    else
      case blob do
        <<size::integer, remainder::binary>> ->
          {flags, size, remainder}
        _ ->
          :error
      end
    end
  end

  def extract_flags_and_size(_) do
    :error
  end

  defp parse_flags(flags_byte) do
    %{
      more: (flags_byte &&& @more_flag) > 0,
      long: (flags_byte &&& @long_flag) > 0,
      command: (flags_byte &&& @command_flag) > 0,
    }
  end

  def encode_command(command) do
    encode(to_string(command), more: false, command: true)
  end

  def encode_message(message) do
    encode(message.body, more: message.more, command: false)
  end

  defp encode(body, more: more, command: command) do
    unless is_binary(body) do
      raise ArgumentError, message: "Frame body must be a binary blob"
    end

    flags = 0b000

    body_size = byte_size(body)

    if body_size > 255 do
      flags = flags + @long_flag
      body_size = <<body_size::8 * 8>>
    else
      body_size = <<body_size::1 * 8>>
    end

    if more do
      flags = flags + @more_flag
    end

    if command do
      flags = flags + @command_flag
    end

    <<flags, body_size::binary, body::binary>>
  end
end
