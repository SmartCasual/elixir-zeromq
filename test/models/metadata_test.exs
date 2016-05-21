defmodule ElixirZeroMQ.MetadataTest do
  use ExUnit.Case, async: true

  test ".encode explodes without binary blobs" do
    assert_raise ArgumentError, fn ->
      ElixirZeroMQ.Metadata.encode(%{
        123 => "value",
      })
    end

    assert_raise ArgumentError, fn ->
      ElixirZeroMQ.Metadata.encode(%{
        "key" => 123,
      })
    end
  end

  test "encodes maps of strings sorted alphabetically" do
    encoded_metadata = ElixirZeroMQ.Metadata.encode(%{
      "Server-Type" => "Some Server Type",
      "Identity" => "12",
    })

    expected_encoding = <<
      8, "Identity",
      2::4 * 8, "12",
      11, "Server-Type",
      16::4 * 8, "Some Server Type",
    >>

    assert encoded_metadata == expected_encoding
  end
end