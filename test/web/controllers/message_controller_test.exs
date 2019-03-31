defmodule Web.MessageControllerTest do
  use Web.ConnCase
  use Web.ChannelCase
  use JanusEx.RoomCase
  alias JanusEx.Room

  test "post message", %{conn: conn, room_name: room_name} do
    params = %{
      "message" => %{
        "name" => "Joe",
        "content" => "hello from joe"
      }
    }

    @endpoint.subscribe("rooms")
    @endpoint.subscribe("room:#{room_name}")

    conn = post(conn, "/#{room_name}/messages", params)
    assert redirected_to(conn) == "/#{room_name}"

    expected_message = %Room.Message{author: "Joe", content: "hello from joe"}

    assert_broadcast "message:new", %{"message" => ^expected_message, "room_name" => ^room_name}
    assert_broadcast "message:new", %{"message" => ^expected_message}

    assert [expected_message] == Room.list_messages(room_name)
  end
end
