defmodule ZeroMQ.NullSecurityMechanism do
  @moduledoc """
  A GenServer which manages the state machine for the NULL security mechanism.
  """

  @doc """
  Returns a greeting pre-set with the NULL security mechanism.
  """
  def greeting do
    %ZeroMQ.Greeting{mechanism: "NULL"}
  end

  use GenServer

  @doc """
  Starts a NULL security mechanism in an unready state.
  """
  def start_link(metadata, peer_type, callbacks) do
    unless peer_type == :binding or peer_type == :connecting do
      raise ArgumentError, message: "Peer type must be :binding or :connecting"
    end

    GenServer.start_link(__MODULE__, {metadata, peer_type, callbacks}, [])
  end

  def process_command(security_mechanism, command) do
   GenServer.call(security_mechanism, {:process_command, command})
  end

  def init({metadata, peer_type, callbacks}) do
    if peer_type == :connecting do
      callbacks[:peer_delivery].(ready_command(metadata))
    end

    state = %ZeroMQ.NullSecurityMechanismState{
      metadata: metadata,
      peer_type: peer_type,
      callbacks: callbacks,
      phase: :unready,
    }

    {:ok, state}
  end

  def handle_call({:process_command, command}, _from, state) do
    if state.phase == :unready and command.name == "READY" do
      peer_metadata = ZeroMQ.Metadata.parse(command.data)

      if ZeroMQ.SocketTypes.valid_combination?(state.metadata["Socket-Type"], peer_metadata["Socket-Type"]) do
        if state.peer_type == :binding do
          state.callbacks[:peer_delivery].(ready_command(state.metadata))
        end

        {:reply, {:ok, :complete}, %{state | phase: :ready}}
      else
        {:reply, {:error, "Invalid socket type combination"}, %{state | phase: :abort}}
      end
    else
      if state.phase == :ready do
        {:reply, {:ok, :complete}, state}
      else
        {:reply, {:ok, :incomplete}, state}
      end
    end
  end

  defp ready_command(metadata) do
    metadata_blob = ZeroMQ.Metadata.encode(metadata)
    %ZeroMQ.Command{name: "READY", data: metadata_blob}
  end
end
