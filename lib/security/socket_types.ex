defmodule ZeroMQ.SocketTypes do
  @valid_socket_combinations [
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

  @doc """
  Validates the two peer socket types based on the following table
  from http://rfc.zeromq.org/spec:37#toc16

  | types  | REQ | REP | DEALER | ROUTER | PUB | XPUB | SUB | XSUB | PUSH | PULL | PAIR |
  | ------ | --- | --- | ------ | ------ | --- | ---- | --- | ---- | ---- | ---- | ---- |
  | REQ    |     |  *  |        |   *    |     |      |     |      |      |      |      |
  | REP    |  *  |     |   *    |        |     |      |     |      |      |      |      |
  | DEALER |     |  *  |   *    |   *    |     |      |     |      |      |      |      |
  | ROUTER |  *  |     |   *    |   *    |     |      |     |      |      |      |      |
  | PUB    |     |     |        |        |     |      |  *  |  *   |      |      |      |
  | XPUB   |     |     |        |        |     |      |  *  |  *   |      |      |      |
  | SUB    |     |     |        |        |  *  |  *   |     |      |      |      |      |
  | XSUB   |     |     |        |        |  *  |  *   |     |      |      |      |      |
  | PUSH   |     |     |        |        |     |      |     |      |      |  *   |      |
  | PULL   |     |     |        |        |     |      |     |      |  *   |      |      |
  | PAIR   |     |     |        |        |     |      |     |      |      |      |  *   |

  """
  def valid_combination?(peer_1, peer_2) do
    Enum.member?(@valid_socket_combinations, {peer_1, peer_2})
  end
end
