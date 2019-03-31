defmodule JanusEx.Room do
  @moduledoc "Models a room with its message history in memory"
  use GenServer, restart: :transient
  # TODO maybe stop the process after some idle time
  # TODO add history limit

  @derive Jason.Encoder
  defstruct [:name, history: []]

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
          name: String.t()
        }

  @doc false
  def start_link(opts) do
    name = opts[:name] || raise("need :name")
    GenServer.start_link(__MODULE__, opts, name: via(name))
  end

  defp via(name) when is_binary(name) do
    {:via, Registry, {JanusEx.Room.Registry, name}}
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
  def init(opts) do
    {:ok, %__MODULE__{name: opts[:name]}}
  end

  @impl true
  def handle_call({:save_message, message}, _from, %__MODULE__{history: history} = state) do
    {:reply, :ok, %{state | history: [message | history]}}
  end

  def handle_call(:list_messages, _from, %__MODULE__{history: history} = state) do
    {:reply, history, state}
  end
end
