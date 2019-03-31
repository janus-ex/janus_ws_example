import RoomList from "./components/RoomList.html";
import MessageList from "./components/MessageList.html";
import MessageForm from "./components/MessageForm.html";
import socket from "./socket";

// TODO will need to refactor it later someday

let roomsTarget = document.querySelector("section#rooms");
let messagesTarget = document.querySelector("section#messages");
let messagesFormTarget = document.querySelector("form#messages-form");

if (roomsTarget) {
  let roomsChannel = socket.channel("rooms", {});

  let roomListPromise = new Promise((resolve, reject) => {
    roomsChannel.join().receive("ok", ({ rooms }) => {
      resolve(
        new RoomList({
          target: roomsTarget,
          hydrate: true,
          data: {
            rooms: rooms.map(({ name, history }) => {
              return { name, lastMessage: history[0] };
            })
          }
        })
      );
    });
  });

  roomListPromise.then(roomList => {
    roomsChannel.on("new", ({ room: { name, history } }) => {
      let rooms = roomList.get().rooms;
      rooms.push({ name, lastMessage: history[0] });
      roomList.set({ rooms });
    });

    roomsChannel.on("message:new", ({ room_name, message }) => {
      let rooms = roomList.get().rooms.map(room => {
        if (room.name === room_name) {
          room.lastMessage = message;
        }

        return room;
      });

      roomList.set({ rooms });
    });
  });
}

if (messagesTarget && messagesFormTarget) {
  let roomChannel = socket.channel(`room:${roomName}`);

  let messageHistoryPromise = new Promise((resolve, reject) => {
    roomChannel.join().receive("ok", ({ history }) => {
      history.reverse();
      resolve(history);
    });
  });

  messageHistoryPromise.then(messages => {
    let messageList = new MessageList({
      target: messagesTarget,
      hydrate: true,
      data: { messages }
    });

    roomChannel.on("message:new", ({ message }) => {
      let messages = messageList.get().messages;
      messages.push(message);
      messageList.set({ messages });
    });
  });

  let messageForm = new MessageForm({
    target: messagesFormTarget,
    hydrate: true,
    data: {
      submitEnabled: true,
      name: messagesFormTarget.querySelector("input#message_name").value,
      content: messagesFormTarget.querySelector("textarea#message_content")
        .value
    }
  });

  messageForm.on("submit", ({ name, content }) => {
    roomChannel.push("message:new", { name, content }).receive("ok", resp => {
      messageForm.set({ content: "", submitEnabled: true });
    });
  });

  // TODO sdp
}
