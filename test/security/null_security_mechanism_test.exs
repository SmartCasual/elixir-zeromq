defmodule ZeroMQ.NullSecurityMechanismTest do
  use ExUnit.Case, async: true

  setup do
    test_process = self()

    callbacks = %{
      peer_delivery: fn frame_blob ->
        send test_process, {:sent_to_peer, frame_blob}
      end,
    }

    {:ok,
      callbacks: callbacks,
      null_mechanism: {:ok, _} = ZeroMQ.NullSecurityMechanism.start_link(
        %{},
        :binding,
        callbacks
      ),
    }
  end

  test ".greeting returns a greeting containing NULL security" do
    greeting = ZeroMQ.NullSecurityMechanism.greeting
    assert greeting == %ZeroMQ.Greeting{mechanism: "NULL"}
  end

  test "can be binding or connecting", context do
    {:ok, _} = ZeroMQ.NullSecurityMechanism.start_link(%{}, :binding, context[:callbacks])
    {:ok, _} = ZeroMQ.NullSecurityMechanism.start_link(%{}, :connecting, context[:callbacks])

    assert_raise ArgumentError, fn ->
      ZeroMQ.NullSecurityMechanism.start_link(%{}, :something_else, context[:callbacks])
    end
  end

  test "if connecting, sends a ready command immediately", context do
    metadata = %{"Socket-Type" => "PAIR"}
    {:ok, _} = ZeroMQ.NullSecurityMechanism.start_link(metadata, :connecting, context[:callbacks])

    metadata_blob = ZeroMQ.Metadata.encode(metadata)
    ready_command = %ZeroMQ.Command{name: "READY", data: metadata_blob}

    assert_received {:sent_to_peer, ^ready_command}
  end

  test "if binding, sends a ready command after receiving one", context do
    metadata = %{"Socket-Type" => "PAIR"}
    {:ok, mechanism} = ZeroMQ.NullSecurityMechanism.start_link(metadata, :binding, context[:callbacks])

    metadata_blob = ZeroMQ.Metadata.encode(metadata)
    ready_command = %ZeroMQ.Command{name: "READY", data: metadata_blob}

    refute_received {:sent_to_peer, ^ready_command}

    ZeroMQ.NullSecurityMechanism.process_command(mechanism, ready_command)

    assert_received {:sent_to_peer, ^ready_command}
  end

  test "sends nothing if either not in unready state or not READY command", context do
    metadata = %{"Socket-Type" => "PAIR"}
    {:ok, mechanism} = ZeroMQ.NullSecurityMechanism.start_link(metadata, :binding, context[:callbacks])

    metadata_blob = ZeroMQ.Metadata.encode(metadata)
    not_ready_command = %ZeroMQ.Command{name: "OTHER", data: metadata_blob}
    {:ok, :incomplete} = ZeroMQ.NullSecurityMechanism.process_command(mechanism, not_ready_command)

    refute_received {:sent_to_peer, _}

    # Ready up
    ready_command = %ZeroMQ.Command{name: "READY", data: metadata_blob}
    {:ok, :complete} = ZeroMQ.NullSecurityMechanism.process_command(mechanism, ready_command)

    # Clear READY response from mailbox
    receive do
      {:sent_to_peer, _} -> nil
    end

    # Receive a READY command when already ready
    ready_command = %ZeroMQ.Command{name: "READY", data: metadata_blob}
    {:ok, :complete} = ZeroMQ.NullSecurityMechanism.process_command(mechanism, ready_command)

    refute_received {:sent_to_peer, _}
  end

  test "if binding, errors if the socket type combination is invalid", context do
    metadata = %{"Socket-Type" => "PAIR"}
    peer_metadata = %{"Socket-Type" => "SUB"}
    {:ok, mechanism} = ZeroMQ.NullSecurityMechanism.start_link(metadata, :binding, context[:callbacks])

    metadata_blob = ZeroMQ.Metadata.encode(peer_metadata)
    ready_command = %ZeroMQ.Command{name: "READY", data: metadata_blob}

    result = ZeroMQ.NullSecurityMechanism.process_command(mechanism, ready_command)
    assert result == {:error, "Invalid socket type combination"}
  end

  test "if connecting, errors if the socket type combination is invalid", context do
    metadata = %{"Socket-Type" => "PAIR"}
    peer_metadata = %{"Socket-Type" => "SUB"}
    {:ok, mechanism} = ZeroMQ.NullSecurityMechanism.start_link(metadata, :connecting, context[:callbacks])

    metadata_blob = ZeroMQ.Metadata.encode(peer_metadata)
    ready_command = %ZeroMQ.Command{name: "READY", data: metadata_blob}

    result = ZeroMQ.NullSecurityMechanism.process_command(mechanism, ready_command)
    assert result == {:error, "Invalid socket type combination"}
  end
end
