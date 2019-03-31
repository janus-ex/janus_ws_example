defmodule JanusEx.RoomTest do
  use JanusEx.RoomCase

  @registry JanusEx.Room.Registry
  alias JanusEx.Room

  describe "starting a room process" do
    test "with list_messages/1", %{room_name: room_name} do
      assert [] == Registry.lookup(@registry, room_name)
      assert [] == Room.list_messages(room_name)

      assert [{pid, _}] = Registry.lookup(@registry, room_name)
      assert Process.alive?(pid)
      assert %Room{name: room_name, history: []} == :sys.get_state(pid)
    end

    test "with save_message/2", %{room_name: room_name} do
      assert [] == Registry.lookup(@registry, room_name)
      message = %Room.Message{author: "Billy", content: "Hi there!"}
      assert :ok == Room.save_message(room_name, message)

      assert [{pid, _}] = Registry.lookup(@registry, room_name)
      assert Process.alive?(pid)
      assert %Room{name: room_name, history: [message]} == :sys.get_state(pid)
    end
  end

  describe "save_message/2" do
    test "save two messages and then list them", %{room_name: room_name} do
      m1 = %Room.Message{author: "Billy", content: "Hi there!"}
      m2 = %Room.Message{author: "Joe", content: "Hey there!"}
      assert :ok == Room.save_message(room_name, m1)
      assert :ok == Room.save_message(room_name, m2)

      assert [m2, m1] == Room.list_messages(room_name)
    end
  end

  describe "list_rooms/0" do
    test "when there are rooms" do
      r1 = room_name()
      r2 = room_name()
      r3 = room_name()

      Enum.each([r1, r2, r3], fn room_name ->
        assert [] == Room.list_messages(room_name)
      end)

      rooms = Room.list_rooms()

      # TODO fix stray rooms
      assert %JanusEx.Room{history: [], name: r1} in rooms
      assert %JanusEx.Room{history: [], name: r2} in rooms
      assert %JanusEx.Room{history: [], name: r3} in rooms
    end
  end
end
