defmodule WebGib.Plugs.EnsureMetaQuery do
  @moduledoc """
  The MetaQuery for a user is a query that searches for all of that user's
  query (result) ib_gib.
  """

  require Logger
  import Plug.Conn
  import Phoenix.Controller

  import WebGib.Gettext
  use IbGib.Constants, :ib_gib
  use WebGib.Constants, :keys
  import IbGib.{Expression, QueryOptionsFactory}

  @doc """
  This options is created at "compile time" (when there is a request).
  It is then passed to the `call/2` function, so whatever is returned here
  will be used at runtime there.

  Returns `:ok` by default.
  """
  def init(options) do
    options
  end

  @doc """

  """
  def call(conn, options) do
    Logger.debug "ensure meta query hooraaaaah."
    current = conn |> get_session(@ib_meta_query_ib_gib_key)

    if current == nil do
      identity_ib_gibs = conn |> get_session(@identity_ib_gibs_key)

      # We need to create the user's most recent
      query_opts =
        do_query
        |> where_ib("is", "query_result")
        |> where_rel8ns("ancestor", "with", "ibgib", "query_result#{@delim}gib")
        |> where_rel8ns("identity", "in", "ibgib", identity_ib_gibs)


      Logger.debug "current ib session is nil"

      conn
      |> put_flash(:error, gettext "Please read ibGib's vision before using our application!")
      |> redirect(to: "/")
      |> halt
    else
      Logger.debug "current ib session exists"
      conn
    end
  end
end
