defmodule WebGib.Router do
  use WebGib.Web, :router
  use Phoenix.Socket


  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug WebGib.Plugs.IbGibDefaults
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WebGib do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    post "/", PageController, :index

    get "/ibgib", IbGibController, :index
    get "/ibgib/:ib_or_ib_gib", IbGibController, :show

    post "ibgib/api/fork", IbGibController, :fork
  end

  # Other scopes may use custom stacks.
  # scope "/api", WebGib do
  #   pipe_through :api
  # end

  # socket "/ws", WebGib do
  #   channel "rooms:*", RoomChannel
  # end
end
