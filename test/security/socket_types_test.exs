defmodule ZeroMQ.SocketTypesTest do
  use ExUnit.Case, async: true

  test "valid_combination?(peer_1, peer_2)" do
    Enum.each(valid_socket_combinations, fn {peer_1, peer_2} ->
      failure_message = "{#{peer_1}, #{peer_2}} was not a valid combination"
      assert ZeroMQ.SocketTypes.valid_combination?(peer_1, peer_2), failure_message
    end)

    Enum.each(invalid_socket_combinations, fn {peer_1, peer_2} ->
      failure_message = "{#{peer_1}, #{peer_2}} was incorrectly a valid combination"
      refute ZeroMQ.SocketTypes.valid_combination?(peer_1, peer_2), failure_message
    end)
  end

  defp valid_socket_combinations do
    [
      {"REQ", "REP"},
      {"REQ", "ROUTER"},

      {"REP", "REQ"},
      {"REP", "DEALER"},

      {"DEALER", "REP"},
      {"DEALER", "DEALER"},
      {"DEALER", "ROUTER"},

      {"PUB", "SUB"},
      {"PUB", "XSUB"},

      {"XPUB", "SUB"},
      {"XPUB", "XSUB"},

      {"SUB", "PUB"},
      {"SUB", "XPUB"},

      {"XSUB", "PUB"},
      {"XSUB", "XPUB"},

      {"PUSH", "PULL"},
      {"PULL", "PUSH"},

      {"PAIR", "PAIR"},
    ]
  end

  defp invalid_socket_combinations do
    [
      {"REQ", "REQ"},
      {"REQ", "DEALER"},
      {"REQ", "PUB"},
      {"REQ", "XPUB"},
      {"REQ", "SUB"},
      {"REQ", "XSUB"},
      {"REQ", "PUSH"},
      {"REQ", "PULL"},
      {"REQ", "PAIR"},

      {"REP", "REP"},
      {"REP", "ROUTER"},
      {"REP", "PUB"},
      {"REP", "XPUB"},
      {"REP", "SUB"},
      {"REP", "XSUB"},
      {"REP", "PUSH"},
      {"REP", "PULL"},
      {"REP", "PAIR"},

      {"DEALER", "REQ"},
      {"DEALER", "PUB"},
      {"DEALER", "XPUB"},
      {"DEALER", "SUB"},
      {"DEALER", "XSUB"},
      {"DEALER", "PUSH"},
      {"DEALER", "PULL"},
      {"DEALER", "PAIR"},

      {"PUB", "REQ"},
      {"PUB", "REP"},
      {"PUB", "DEALER"},
      {"PUB", "ROUTER"},
      {"PUB", "PUB"},
      {"PUB", "XPUB"},
      {"PUB", "PUSH"},
      {"PUB", "PULL"},
      {"PUB", "PAIR"},

      {"XPUB", "REQ"},
      {"XPUB", "REP"},
      {"XPUB", "DEALER"},
      {"XPUB", "ROUTER"},
      {"XPUB", "PUB"},
      {"XPUB", "XPUB"},
      {"XPUB", "PUSH"},
      {"XPUB", "PULL"},
      {"XPUB", "PAIR"},

      {"SUB", "REQ"},
      {"SUB", "REP"},
      {"SUB", "DEALER"},
      {"SUB", "ROUTER"},
      {"SUB", "SUB"},
      {"SUB", "XSUB"},
      {"SUB", "PUSH"},
      {"SUB", "PULL"},
      {"SUB", "PAIR"},

      {"XSUB", "REQ"},
      {"XSUB", "REP"},
      {"XSUB", "DEALER"},
      {"XSUB", "ROUTER"},
      {"XSUB", "SUB"},
      {"XSUB", "XSUB"},
      {"XSUB", "PUSH"},
      {"XSUB", "PULL"},
      {"XSUB", "PAIR"},

      {"PUSH", "REQ"},
      {"PUSH", "REP"},
      {"PUSH", "DEALER"},
      {"PUSH", "ROUTER"},
      {"PUSH", "PUB"},
      {"PUSH", "XPUB"},
      {"PUSH", "SUB"},
      {"PUSH", "XSUB"},
      {"PUSH", "PUSH"},
      {"PUSH", "PAIR"},

      {"PULL", "REQ"},
      {"PULL", "REP"},
      {"PULL", "DEALER"},
      {"PULL", "ROUTER"},
      {"PULL", "PUB"},
      {"PULL", "XPUB"},
      {"PULL", "SUB"},
      {"PULL", "XSUB"},
      {"PULL", "PULL"},
      {"PULL", "PAIR"},

      {"PAIR", "REQ"},
      {"PAIR", "REP"},
      {"PAIR", "DEALER"},
      {"PAIR", "ROUTER"},
      {"PAIR", "PUB"},
      {"PAIR", "XPUB"},
      {"PAIR", "SUB"},
      {"PAIR", "XSUB"},
      {"PAIR", "PUSH"},
      {"PAIR", "PULL"},
    ]
  end
end
