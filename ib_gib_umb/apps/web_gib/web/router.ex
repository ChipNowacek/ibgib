defmodule WebGib.Router do
  use WebGib.Web, :router
  # use Phoenix.Socket

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
    # plug WebGib.Plugs.AggregateIDHash
    plug WebGib.Plugs.EnsureMetaQuery
    plug WebGib.Plugs.IbGibRoot
  end

  scope "/", WebGib do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/ibgib", WebGib do
    pipe_through [:browser, :ib_gib_pipe]

    get "/", IbGibController, :index
    post "/", IbGibController, :index
    get "/:ib_or_ib_gib", IbGibController, :show
    get "/ident/:token", IbGibController, :ident

    post "/fork", IbGibController, :fork
    post "/comment", IbGibController, :comment
    post "/pic", IbGibController, :pic
    post "/link", IbGibController, :link
    post "/ident", IbGibController, :ident
    post "/query", IbGibController, :query
  end

  scope "/api", WebGib do
    pipe_through [:api]

    # Get ibgibs via just ib
    # get "/ib/:ib", IbGibController, :get
    get "/ibgib/:ib_gib", IbGibController, :get
    get "/ibgib/d3/:ib_gib", IbGibController, :getd3
  end

  # socket "/ws", WebGib do
  #   channel "rooms:*", RoomChannel
  # end
end
