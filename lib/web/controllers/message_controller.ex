defmodule Web.MessageController do
  use Web, :controller
  alias JanusEx.Room

  def create(conn, %{
        "message" => %{"content" => content} = message_params,
        "room_name" => room_name
      }) do
    message = %Room.Message{author: username(message_params["name"]), content: content}
    :ok = Room.save_message(room_name, message)

    Web.Endpoint.broadcast!("room:#{room_name}", "message:new", %{"message" => message})

    Web.Endpoint.broadcast!("rooms", "message:new", %{
      "room_name" => room_name,
      "message" => message
    })

    redirect(conn, to: Routes.room_path(conn, :show, room_name))
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
