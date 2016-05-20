defmodule ElixirZeroMQ.Message do
  defstruct body: nil,
            more: false

  def parse(<<0x00, size, body::binary-size(size)>>) do
    %__MODULE__{
      body: body,
      more: false,
    }
  end

  def parse(<<0x01, size, body::binary-size(size)>>) do
    %__MODULE__{
      body: body,
      more: true,
    }
  end

  def parse(<<0x02, size::8 * 8, body::binary-size(size)>>) do
    %__MODULE__{
      body: body,
      more: false,
    }
  end

  def parse(<<0x03, size::8 * 8, body::binary-size(size)>>) do
    %__MODULE__{
      body: body,
      more: true,
    }
  end
end

defimpl String.Chars, for: ElixirZeroMQ.Message do
  def to_string(message) do
    unless is_binary(message.body) do
      raise ArgumentError, message: "Message body must be a binary blob"
    end

    body_size = byte_size(message.body)
    if body_size > 255 do
      if message.more do
        body_size = <<0x03, body_size::8 * 8>>
      else
        body_size = <<0x02, body_size::8 * 8>>
      end
    else
      if message.more do
        body_size = <<0x01, body_size::1 * 8>>
      else
        body_size = <<0x00, body_size::1 * 8>>
      end
    end

    <<body_size::binary, message.body::binary>>
  end
end
