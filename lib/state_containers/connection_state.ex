defmodule ZeroMQ.ConnectionState do
  defstruct callbacks: nil,
            splitter: nil,
            socket_type: nil,
            phase: nil
end
