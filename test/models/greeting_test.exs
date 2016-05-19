defmodule ElixirZeroMQ.GreetingTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, default_greeting: %ElixirZeroMQ.Greeting{}}
  end

  test "default signature", context do
    expected_signature = <<0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x7f>>
    assert context[:default_greeting].signature == expected_signature
  end

  test "default version", context do
    assert context[:default_greeting].version == "3.1"
  end

  test "default mechanism", context do
    assert context[:default_greeting].mechanism == "NULL"
  end

  test "default as_server", context do
    assert context[:default_greeting].as_server == false
  end

  test "default filler", context do
    expected_filler = <<
      0x00,0x00,0x00,0x00,0x00,
      0x00,0x00,0x00,0x00,0x00,
      0x00,0x00,0x00,0x00,0x00,
      0x00,0x00,0x00,0x00,0x00,
      0x00,0x00,0x00,0x00,0x00,
      0x00,0x00,0x00,0x00,0x00,
      0x00
    >>

    assert context[:default_greeting].filler == expected_filler
  end

  test "presented default mechanism", context do
    expected_mechanism = <<
      "NULL",0x00,
      0x00,0x00,0x00,0x00,0x00,
      0x00,0x00,0x00,0x00,0x00,
      0x00,0x00,0x00,0x00,0x00
    >>

    actual_mechanism = parsed_greeting(context[:default_greeting])[:mechanism]

    assert actual_mechanism == expected_mechanism
  end

  test "presented mechanism is autopadded to 20 bytes" do
    greeting = %ElixirZeroMQ.Greeting{mechanism: "10BYTE_STR"}

    expected_mechanism = <<
      "10BYTE_STR",
      0x00,0x00,0x00,0x00,0x00,
      0x00,0x00,0x00,0x00,0x00
    >>

    actual_mechanism = parsed_greeting(greeting)[:mechanism]

    assert actual_mechanism == expected_mechanism
  end

  test "presented default as_server", context do
    actual_as_server = parsed_greeting(context[:default_greeting])[:as_server]
    assert actual_as_server == <<0>>
  end

  test "presented as_server when true" do
    greeting = %ElixirZeroMQ.Greeting{as_server: true}
    assert parsed_greeting(greeting)[:as_server] == <<1>>
  end

  test "presented default version", context do
    assert parsed_greeting(context[:default_greeting])[:version] == <<3,1>>
  end

  test "presented version when set" do
    greeting = %ElixirZeroMQ.Greeting{version: "4.5"}
    assert parsed_greeting(greeting)[:version] == <<4,5>>
  end

  defp parsed_greeting(greeting) do
    <<
      signature::size(10)-unit(8)-binary,
      version::size(2)-unit(8)-binary,
      mechanism::size(20)-unit(8)-binary,
      as_server::size(1)-unit(8)-binary,
      filler::size(31)-unit(8)-binary
    >> = to_string(greeting)

    %{
      signature: signature,
      version: version,
      mechanism: mechanism,
      as_server: as_server,
      filler: filler
    }
  end
end
