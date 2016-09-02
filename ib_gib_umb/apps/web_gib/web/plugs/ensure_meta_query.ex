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
  alias IbGib.Helper
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
    Logger.debug "ensure meta_query_result_ib_gib in session hooraaaaah."
    current = conn |> get_session(@meta_query_result_ib_gib_key)

    if current == nil do
      Logger.debug "current meta query ib_gib is nil"
      identity_ib_gibs = conn |> get_session(@identity_ib_gibs_key)

      conn =
        with {:ok, query_opts} <- get_meta_query_opts(identity_ib_gibs),
          {:ok, first_identity} <- get_first_identity(identity_ib_gibs),
          {:ok, meta_query_result} <- first_identity |> query(query_opts),
          {:ok, meta_query_result_info} <- meta_query_result |> get_info,
          {:ok, meta_query_ib_gib} <-
            get_meta_query_ib_gib(meta_query_result_info),
          {:ok, meta_query_result_ib_gib} <-
            Helper.get_ib_gib(meta_query_result_info) do

          Logger.warn "meta_query_result_ib_gib: #{meta_query_result_ib_gib}"
          Logger.warn "meta_query_result_info: #{inspect meta_query_result_info}"
          conn |> put_session(@meta_query_ib_gib_key,
                              meta_query_ib_gib)
          conn |> put_session(@meta_query_result_ib_gib_key,
                              meta_query_result_ib_gib)
          Logger.debug "inserted meta query ib^gib into session: #{meta_query_ib_gib}"
          Logger.debug "inserted meta query result ib^gib into session: #{meta_query_result_ib_gib}"
          conn
        else
          error ->
            Logger.error "Error: #{inspect error}"
            conn
            |> put_flash(:error, gettext "There was a problem getting your meta query (Oh no!). Do you have a lot of them? Maybe it timed out.")
            |> redirect(to: "/")
            |> halt
        end
      conn
    else
      Logger.debug "current meta query ib_gib is NOT nil"
      conn
    end
  end

  defp get_meta_query_opts(identity_ib_gibs) do
    # We need to create the user's most recent
    query_opts =
      do_query
      |> where_ib("is", "query_result")
      |> where_rel8ns("ancestor", "with", "ibgib", "query_result#{@delim}gib")
      |> where_rel8ns("identity", "withany", "ibgib", identity_ib_gibs)
    {:ok, query_opts}
  end

  defp get_first_identity(identity_ib_gibs) do
    first_identity_ib_gib = Enum.at(identity_ib_gibs, 0)
    first_identity =
      IbGib.Expression.Supervisor.start_expression(first_identity_ib_gib)
  end

  defp get_meta_query_ib_gib(meta_query_result_info) do
    case Enum.at(meta_query_result_info[:rel8ns]["query"], 0) do
      nil -> {:error, "Meta query ib^gib not found in query result."}
      meta_query_ib_gib -> {:ok, meta_query_ib_gib}
    end
  end
end
