defmodule Web.RoomChannel do
  @moduledoc """
  Mostly used to relay SDPs to janus, also handles some basic text chat functionality
  """
  use Web, :channel

  def join("room:" <> _room_id, _params, socket) do
    {:ok, socket}
  end
end
