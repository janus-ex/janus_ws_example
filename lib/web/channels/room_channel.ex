defmodule Web.RoomChannel do
  @moduledoc """
  Mostly used to relay SDPs to janus, also handles some basic text chat functionality
  """
  use Web, :channel
  alias JanusEx.Room
  alias Janus.WS, as: Janus

  @client Janus

  def join("room:" <> room_name, _params, socket) do
    {:ok, tx_id} = Janus.create_session(@client)

    socket =
      socket
      |> assign(:room_name, room_name)
      |> assign(:txs, %{tx_id => :session})

    {:ok, %{history: Room.list_messages(room_name)}, socket}
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

  def handle_in("candidate", candidate, socket) do
    %{session_id: session_id, handle_id: handle_id, txs: txs} = socket.assigns
    {:ok, tx_id} = Janus.send_trickle_candidate(@client, session_id, handle_id, candidate)
    {:reply, :ok, assign(socket, :txs, Map.put(txs, tx_id, :trickle))}
  end

  def handle_in("offer", offer, socket) do
    %{session_id: session_id, handle_id: handle_id, txs: txs} = socket.assigns

    {:ok, tx_id} =
      Janus.send_message(@client, session_id, handle_id, %{
        "jsep" => offer,
        "body" => %{"request" => "configure"}
      })

    {:reply, :ok, assign(socket, :txs, Map.put(txs, :configure, tx_id))}
  end

  def handle_info(:keepalive, socket) do
    Janus.send_keepalive(@client, socket.assigns.session_id)
    Process.send_after(self(), :keepalive, 30_000)
    {:noreply, socket}
  end

  def handle_info(:join_janus_room, socket) do
    %{room_name: room_name, session_id: session_id, handle_id: handle_id, txs: txs} =
      socket.assigns

    socket =
      if Room.janus_room_created?(room_name) do
        {:ok, tx_id} =
          Janus.send_message(@client, session_id, handle_id, %{
            "body" => %{
              "request" => "join",
              "room" => Room.janus_room_id(room_name)
            }
          })

        assign(socket, :txs, Map.put(txs, tx_id, :join))
      else
        Process.send_after(self(), :join_janus_room, 1000)
        socket
      end

    {:noreply, socket}
  end

  # TODO msg = {:janus_ws, ...}
  def handle_info(msg, socket) do
    socket = handle_janus_msg(msg, socket)
    {:noreply, socket}
  end

  defp handle_janus_msg(%{"transaction" => tx_id} = msg, socket) do
    txs = socket.assigns.txs

    case Map.pop(txs, tx_id) do
      {:session, txs} ->
        %{"janus" => "success", "data" => %{"id" => session_id}} = msg
        {:ok, _owner_id} = Registry.register(Janus.Session.Registry, session_id, [])
        {:ok, tx_id} = Janus.attach(@client, session_id, "janus.plugin.audiobridge")
        Process.send_after(self(), :keepalive, 30_000)

        socket
        |> assign(:session_id, session_id)
        |> assign(:txs, Map.put(txs, tx_id, :handle))

      {:handle, txs} ->
        session_id = socket.assigns.session_id

        %{
          "data" => %{"id" => handle_id},
          "janus" => "success",
          "session_id" => ^session_id,
          "transaction" => ^tx_id
        } = msg

        room_name = socket.assigns.room_name

        socket =
          if Room.janus_room_created?(room_name) do
            {:ok, tx_id} =
              Janus.send_message(@client, session_id, handle_id, %{
                "body" => %{
                  "request" => "join",
                  "room" => Room.janus_room_id(room_name)
                }
              })

            assign(socket, :txs, Map.put(txs, tx_id, :join))
          else
            Process.send_after(self(), :join_janus_room, 1000)
            assign(socket, :txs, txs)
          end

        assign(socket, :handle_id, handle_id)

      {:join, txs} ->
        %{handle_id: handle_id, session_id: session_id} = socket.assigns

        case msg do
          %{"janus" => "ack", "session_id" => ^session_id} ->
            socket

          %{
            "janus" => "event",
            "plugindata" => %{
              "data" => %{
                "audiobridge" => "joined",
                "id" => participant_id,
                "participants" => _other_participants,
                "room" => _room_id
              },
              "plugin" => "janus.plugin.audiobridge"
            },
            "sender" => ^handle_id,
            "session_id" => ^session_id
          } ->
            push(socket, "gimme_offer", %{})

            socket
            |> assign(:txs, txs)
            |> assign(:participant_id, participant_id)
        end

      {:trickle, txs} ->
        %{session_id: session_id} = socket.assigns
        %{"janus" => "ack", "session_id" => ^session_id} = msg
        assign(socket, :txs, txs)

      {nil, _txs} ->
        %{session_id: session_id, handle_id: handle_id} = socket.assigns

        case msg do
          %{
            "janus" => "event",
            "jsep" =>
              %{
                "sdp" => _sdp,
                "type" => "answer"
              } = answer,
            "plugindata" => %{
              "data" => %{"audiobridge" => "event", "result" => "ok"},
              "plugin" => "janus.plugin.audiobridge"
            },
            "sender" => ^handle_id,
            "session_id" => ^session_id
            # TODO why is transaction not found?
            # "transaction" => "FB0UysgRy+0"
          } ->
            push(socket, "answer", answer)

          _other ->
            IO.inspect(msg, label: "unexpected socket tx message")
        end

        socket
    end
  end

  defp handle_janus_msg(msg, socket) do
    IO.inspect(msg, label: "unexpected socket message")

    socket
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
