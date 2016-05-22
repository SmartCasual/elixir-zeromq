defmodule ZeroMQ.Message do
  defstruct body: nil,
            more: false
end

defimpl String.Chars, for: ZeroMQ.Message do
  def to_string(message) do
    unless is_binary(message.body) do
      raise ArgumentError, message: "Message body must be a binary blob"
    end

    message.body
  end
end
