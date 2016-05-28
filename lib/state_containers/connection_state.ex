defmodule ZeroMQ.ConnectionState do
  defstruct callbacks: nil,
            splitter: nil,
            heartbeat: nil,
            socket_type: nil,
            phase: nil
end
