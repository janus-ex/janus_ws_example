defmodule Web.RoomChannel do
  @moduledoc """
  Mostly used to relay SDPs to janus, also handles some basic text chat functionality
  """
  use Web, :channel
  alias JanusEx.Room

  def join("room:" <> room_name, _params, socket) do
    {:ok, %{history: Room.list_messages(room_name)}, assign(socket, :room_name, room_name)}
  end

  def handle_in("message:new", %{"content" => content} = params, socket) do
    message = %Room.Message{author: username(params["name"]), content: content}
    room_name = socket.assigns.room_name
    :ok = Room.save_message(room_name, message)
    broadcast!(socket, "message:new", %{"message" => message})

    Web.Endpoint.broadcast!("rooms", "message:new", %{
      "room_name" => room_name,
      "message" => message
    })

    {:reply, :ok, socket}
  end

  @spec username(String.t() | nil) :: String.t()
  defp username(name) do
    default_username = "anonymous"

    if name do
      case String.trim(name) do
        "" -> default_username
        other -> other
      end
    else
      default_username
    end
  end
end
