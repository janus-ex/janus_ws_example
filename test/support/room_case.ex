defmodule JanusEx.RoomCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that work with JanusEx.Room processes.
  """

  use ExUnit.CaseTemplate
  alias JanusEx.Room

  using do
    quote do
      import JanusEx.RoomCase
    end
  end

  setup do
    on_exit(fn ->
      # TODO this is also a hack, but will do for now
      Enum.each(Room.list_rooms(), &Room.Supervisor.stop_room/1)
    end)

    Enum.each(Room.list_rooms(), &Room.Supervisor.stop_room/1)

    {:ok, room_name: room_name()}
  end

  def room_name do
    8 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  end
end
