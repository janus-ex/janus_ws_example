defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers
  end

  scope "/", Web do
    pipe_through :browser

    get "/", RoomController, :index
    get "/:room_name", RoomController, :show
    post "/:room_name/messages", MessageController, :create
    put "/:room_name/messages", MessageController, :create
  end
end
