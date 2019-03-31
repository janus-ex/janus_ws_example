defmodule JanusEx.Room.Supervisor do
  @moduledoc false
  use DynamicSupervisor

  @doc false
  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_room(String.t()) :: DynamicSupervisor.on_start_child()
  def start_room(name) do
    DynamicSupervisor.start_child(__MODULE__, {JanusEx.Room, name: name})
  end

  @spec stop_room(String.t()) :: :ok | {:error, :not_found}
  def stop_room(name) do
    case Registry.lookup(JanusEx.Room.Registry, name) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      [] -> {:error, :not_found}
    end
  end
end
