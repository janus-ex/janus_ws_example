defmodule Web.RoomsChannel do
  @moduledoc """
  Sends out updates when a new room is created
  """
  use Web, :channel
  alias JanusEx.Room

  def join("rooms", _params, socket) do
    {:ok, %{rooms: Room.list_rooms()}, socket}
  end
end
