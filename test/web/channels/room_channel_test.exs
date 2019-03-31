defmodule Web.RoomChannelTest do
  use Web.ChannelCase
  use JanusEx.RoomCase
  alias JanusEx.Room

  setup do
    {:ok, socket} = connect(Web.UserSocket, %{}, %{})
    {:ok, socket: socket}
  end

  describe "join a room" do
    test "lists existing messages when room exists", %{socket: socket, room_name: room_name} do
      message = %Room.Message{author: "Boilley", content: "Hoi thire!"}
      assert :ok == Room.save_message(room_name, message)

      {:ok, %{history: [^message]}, _socket} =
        join(socket, "room:#{room_name}", %{"name" => "jeffrey"})
    end

    test "list no messages when room doesn't exist", %{socket: socket, room_name: room_name} do
      {:ok, %{history: []}, _socket} = join(socket, "room:#{room_name}", %{"name" => "jeffry"})
    end
  end

  describe "post message in a room" do
    test "with name", %{socket: socket, room_name: room_name} do
      {:ok, %{history: []}, socket} = subscribe_and_join(socket, "room:#{room_name}", %{})

      ref = push(socket, "message:new", %{"content" => "my name is jeff", "name" => "jeff"})
      assert_reply(ref, :ok, %{})

      expected_message = %Room.Message{author: "jeff", content: "my name is jeff"}
      assert_broadcast("message:new", %{"message" => ^expected_message})
      assert [expected_message] == Room.list_messages(room_name)
    end

    test "without name", %{socket: socket, room_name: room_name} do
      {:ok, %{history: []}, socket} = subscribe_and_join(socket, "room:#{room_name}", %{})

      ref = push(socket, "message:new", %{"content" => "my name is ", "name" => " "})
      assert_reply(ref, :ok, %{})

      expected_message = %Room.Message{author: "anonymous", content: "my name is "}
      assert_broadcast("message:new", %{"message" => ^expected_message})
      assert [expected_message] == Room.list_messages(room_name)
    end
  end
end
