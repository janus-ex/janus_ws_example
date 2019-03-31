defmodule JanusEx.Room.Registry.Listener do
  @moduledoc false
  use GenServer
  alias JanusEx.Room

  @registry JanusEx.Room.Registry

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, []}
  end

  @impl true
  def handle_info({:register, @registry, room_name, _self, _value}, state) do
    # TODO fix the race condition (if we list the room's messages immediately)
    spawn(fn ->
      :timer.sleep(70)
      messages = Room.list_messages(room_name)

      Web.Endpoint.broadcast!("rooms", "new", %{
        "room" => %Room{name: room_name, history: messages}
      })
    end)

    {:noreply, state}
  end
end
