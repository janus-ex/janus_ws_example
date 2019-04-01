defmodule JanusEx.Room do
  @moduledoc "Models a room with its message history in memory"
  use GenServer, restart: :transient
  # TODO maybe stop the process after some idle time
  # TODO add history limit
  # TODO might be a gen_statem probably

  alias Janus.WS, as: Janus
  @client Janus

  @derive Jason.Encoder
  defstruct [:name, :session_id, :handle_id, :room_id, history: [], txs: %{}]

  # TODO fix this
  @interact_with_janus? !!get_in(
                          Application.get_env(:janus_ws_example, __MODULE__),
                          [:interact_with_janus?]
                        )

  defmodule Message do
    @moduledoc "Models a text message in a room"

    @derive Jason.Encoder
    defstruct [:author, :content]

    @type t :: %__MODULE__{
            author: String.t(),
            content: String.t()
          }
  end

  @type t :: %__MODULE__{
          history: [Message.t()],
          name: String.t(),
          txs: %{Janus.tx_id() => atom},
          session_id: pos_integer | nil,
          handle_id: pos_integer | nil,
          room_id: pos_integer | nil
        }

  @doc false
  def start_link(opts) do
    name = opts[:name] || raise("need :name")
    GenServer.start_link(__MODULE__, opts, name: via(name))
  end

  defp via(name) when is_binary(name) do
    {:via, Registry, {JanusEx.Room.Registry, name}}
  end

  @spec janus_room_id(String.t()) :: pos_integer
  def janus_room_id(room_name) do
    :erlang.phash2(room_name)
  end

  # TODO might actually ask janus about whether a room_id=janus_room_id(name) exists
  @spec janus_room_created?(String.t()) :: boolean
  if @interact_with_janus? do
    def janus_room_created?(room_name) do
      call(room_name, :janus_room_created?)
    end
  else
    def janus_room_created?(_room_name) do
      :rand.uniform() > 0.0001
    end
  end

  @spec list_messages(String.t()) :: [Message.t()]
  def list_messages(room_name) do
    call(room_name, :list_messages)
  end

  @spec save_message(String.t(), Message.t()) :: :ok
  def save_message(room_name, message) do
    call(room_name, {:save_message, message})
  end

  @spec list_rooms :: [t]
  def list_rooms do
    # TODO hacky but ok for now
    JanusEx.Room.Supervisor
    |> Supervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} ->
      :sys.get_state(pid)
    end)
  end

  defp call(room_name, message) when is_binary(room_name) do
    GenServer.call(via(room_name), message)
  catch
    :exit, {:noproc, _} ->
      _ = JanusEx.Room.Supervisor.start_room(room_name)
      call(room_name, message)
  end

  @impl true
  if @interact_with_janus? do
    def init(opts) do
      {:ok, tx_id} = Janus.create_session(@client)
      {:ok, %__MODULE__{name: opts[:name], txs: %{tx_id => :session}}}
    end
  else
    def init(opts) do
      {:ok, %__MODULE__{name: opts[:name]}}
    end
  end

  @impl true
  def handle_call({:save_message, message}, _from, %__MODULE__{history: history} = state) do
    {:reply, :ok, %{state | history: [message | history]}}
  end

  def handle_call(:list_messages, _from, %__MODULE__{history: history} = state) do
    {:reply, history, state}
  end

  def handle_call(:janus_room_created?, _from, %__MODULE__{room_id: room_id} = state) do
    {:reply, !!room_id, state}
  end

  @impl true
  def handle_info(:keepalive, %__MODULE__{session_id: session_id} = state) do
    Janus.send_keepalive(@client, session_id)
    Process.send_after(self(), :keepalive, 30_000)
    {:noreply, state}
  end

  # TODO {:janus_ws, msg} = janus_msg
  def handle_info(
        %{"transaction" => tx_id} = msg,
        %__MODULE__{name: name, txs: txs, session_id: session_id, handle_id: handle_id} = state
      ) do
    state =
      case Map.pop(txs, tx_id) do
        {:session, txs} ->
          %{"data" => %{"id" => session_id}, "janus" => "success"} = msg
          {:ok, _owner_id} = Registry.register(Janus.Session.Registry, session_id, [])
          {:ok, tx_id} = Janus.attach(@client, session_id, "janus.plugin.audiobridge")
          Process.send_after(self(), :keepalive, 30_000)
          %{state | txs: Map.put(txs, tx_id, :handle), session_id: session_id}

        {:handle, txs} ->
          %{
            "data" => %{"id" => handle_id},
            "janus" => "success",
            "session_id" => ^session_id
          } = msg

          {:ok, tx_id} =
            Janus.send_message(@client, session_id, handle_id, %{
              "body" => %{
                "request" => "create",
                "room" => janus_room_id(name),
                "description" => name
              }
            })

          %{state | txs: Map.put(txs, tx_id, :room), handle_id: handle_id}

        {:room, txs} ->
          room_id = janus_room_id(name)

          case msg do
            %{
              "janus" => "success",
              "plugindata" => %{
                "data" => %{
                  "audiobridge" => "event",
                  # "error" => "Room 112114386 already exists",
                  "error_code" => 486
                },
                "plugin" => "janus.plugin.audiobridge"
              },
              "sender" => ^handle_id,
              "session_id" => ^session_id
            } ->
              # elixir app has been restarted but janus still remembers about the room
              :ok

            %{
              "janus" => "success",
              "plugindata" => %{
                "data" => %{
                  "audiobridge" => "created",
                  "permanent" => false,
                  "room" => ^room_id
                },
                "plugin" => "janus.plugin.audiobridge"
              },
              "sender" => ^handle_id,
              "session_id" => ^session_id
            } ->
              :ok
          end

          %{state | txs: txs, room_id: room_id}

        {nil, _txs} ->
          IO.inspect(msg, label: "unexpected tx message in room")
          state
      end

    {:noreply, state}
  end

  def handle_info(%{"janus" => "event"} = msg, state) do
    IO.inspect(msg, label: "unexpected event message in room")
    {:noreply, state}
  end
end
