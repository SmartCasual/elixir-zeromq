defmodule ZeroMQ.Connection.Supervisor do
  use Supervisor

  @name __MODULE__

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_connection do
    Supervisor.start_child(@name, [])
  end

  def init(:ok) do
    children = [
      worker(ZeroMQ.Connection, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
