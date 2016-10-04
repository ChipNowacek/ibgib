defmodule WebGib.Router do
  use WebGib.Web, :router
  use Phoenix.Socket

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :ib_gib_pipe do
    plug WebGib.Plugs.EnsureIbGibSession
    plug WebGib.Plugs.IbGibIdentity
    plug WebGib.Plugs.EnsureMetaQuery
    plug WebGib.Plugs.IbGibRoot
  end

  scope "/", WebGib do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    # post "/", PageController, :index

    # get "/ibgib", IbGibController, :index
    # post "/ibgib/login", IbGibController, :login
    # get "/ibgib/:ib_or_ib_gib", IbGibController, :show
    #
    # get "/ibgib/api/fork", IbGibController, :fork
    # get "/ibgib/api/mut8", IbGibController, :mut8
  end

  scope "/ibgib", WebGib do
    pipe_through [:browser, :ib_gib_pipe]

    get "/", IbGibController, :index
    post "/", IbGibController, :index
    get "/:ib_or_ib_gib", IbGibController, :show

    post "/fork", IbGibController, :fork
    post "/comment", IbGibController, :comment
    post "/pic", IbGibController, :pic
    post "/link", IbGibController, :link

    # get "/login", IbGibController, :login
    # post "/login", IbGibController, :login
  end

  scope "/api", WebGib do
    pipe_through [:api]

    # Get ibgibs via just ib
    # get "/ib/:ib", IbGibController, :get
    get "/ibgib/:ib_gib", IbGibController, :get
    get "/ibgib/d3/:ib_gib", IbGibController, :getd3
  end

  # Other scopes may use custom stacks.
  # scope "/api", WebGib do
  #   pipe_through :api
  # end

  # socket "/ws", WebGib do
  #   channel "rooms:*", RoomChannel
  # end
end
