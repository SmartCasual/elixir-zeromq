defmodule ZeroMQ.HeartbeatState do
  defstruct callbacks: nil,
            send_timer: nil,
            ping_timeout: nil
end
