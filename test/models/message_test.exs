defmodule ElixirZeroMQ.MessageTest do
  use ExUnit.Case, async: true

  test "to_string explodes without binary blobs" do
    assert_raise ArgumentError, fn ->
      to_string %ElixirZeroMQ.Message{body: 123}
    end
  end

  test "to_string returns the message body" do
    message = %ElixirZeroMQ.Message{body: "testing 123"}

    assert to_string(message) == "testing 123"
  end
end
