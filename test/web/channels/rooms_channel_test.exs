defmodule Web.RoomsChannelTest do
  use Web.ChannelCase
  use JanusEx.RoomCase
  alias JanusEx.Room

  setup do
    {:ok, socket} = connect(Web.UserSocket, %{}, %{})
    {:ok, socket: socket}
  end

  test "join and get notified about a new room created", %{socket: socket, room_name: room_name} do
    message = %Room.Message{author: "Belley", content: "Hei thire!"}
    assert :ok == Room.save_message(room_name, message)

    # get existing rooms
    # TODO fix stray rooms
    {:ok, %{rooms: rooms}, socket} = subscribe_and_join(socket, "rooms", %{})

    assert %Room{
             history: [message],
             name: room_name
           } in rooms

    # get notified about a new one
    room_name = room_name()
    assert [] == Room.list_messages(room_name)

    assert_broadcast "new", %{"room" => %Room{history: [], name: ^room_name}}

    # and now together with messages
    room_name = room_name()
    assert :ok == Room.save_message(room_name, message)

    assert_broadcast "new", %{
      "room" => %Room{
        history: [^message],
        name: ^room_name
      }
    }

    # now let's get notified about a change in the last message
    assert {:ok, %{history: [^message]}, socket} =
             subscribe_and_join(socket, "room:#{room_name}", %{})

    ref = push(socket, "message:new", %{"content" => "wazzup", "name" => "Donny"})
    assert_reply ref, :ok

    assert_broadcast "message:new", %{
      "room_name" => ^room_name,
      "message" => %Room.Message{author: "Donny", content: "wazzup"}
    }
  end
end
