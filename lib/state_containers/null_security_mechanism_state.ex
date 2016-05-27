defmodule ZeroMQ.NullSecurityMechanismState do
  defstruct callbacks: nil,
            metadata: nil,
            peer_type: nil,
            phase: nil
end
