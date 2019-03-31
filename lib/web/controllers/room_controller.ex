defmodule Web.RoomController do
  use Web, :controller
  alias JanusEx.Room

  def index(conn, _params) do
    rooms = Room.list_rooms()
    render(conn, "index.html", rooms: rooms)
  end

  def show(conn, %{"room_name" => room_name}) do
    messages = Room.list_messages(room_name)
    render(conn, "show.html", messages: :lists.reverse(messages), room_name: room_name)
  end
end
