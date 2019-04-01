import RoomList from "./components/RoomList.html";
import MessageList from "./components/MessageList.html";
import MessageForm from "./components/MessageForm.html";
// import RoomAudio from "./components/RoomAudio.html";
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

  // webrtc stuff

  roomChannel.on("gimme_offer", () => {
    let pc = new RTCPeerConnection({
      iceServers: [{ urls: "stun:stun.l.google.com:19302" }]
    });

    const constraints = { audio: true, video: false };

    pc.oniceconnectionstatechange = evt => {
      console.log("oniceconnectionstatechange", evt);
    };

    pc.onicecandidate = evt => {
      if (evt.candidate) {
        let candidate = {
          candidate: evt.candidate.candidate,
          sdpMid: evt.candidate.sdpMid,
          sdpMLineIndex: evt.candidate.sdpMLineIndex
        };
        roomChannel.push("candidate", candidate);
      } else if (evt.candidate == null) {
        roomChannel.push("candidate", { completed: true });
      }
    };

    pc.ontrack = evt => {
      console.log("handling remote track", evt);
      let roomAudio = document.querySelector("audio#room");
      roomAudio.srcObject = evt.streams[0];
      roomAudio.onloadedmetadata = e => roomAudio.play();
    };

    navigator.mediaDevices
      .getUserMedia(constraints)
      .then(stream => {
        pc.addStream(stream);
        return pc.createOffer();
      })
      .then(offer => {
        console.log("generated offer offer", offer);
        return pc.setLocalDescription(offer);
      })
      .then(() => {
        console.log("sending offer", pc.localDescription);
        roomChannel.push("offer", pc.localDescription);
      })
      .catch(err => {
        console.log(
          "getUserMedia or createOffer or setLocalDescription error",
          err
        );
      });

    roomChannel.on("answer", ({ sdp }) => {
      pc.setRemoteDescription({ type: "answer", sdp: sdp });
    });

    roomChannel.on("candidate", ({ candidate }) => {
      pc.setIceCandidate(candidate);
    });
  });
}
