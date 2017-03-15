defmodule IbGib.Common do
  @moduledoc """
  Common functions to be exposed to whomever. _(Naming things...)_

  ## Use Case

  I'm creating this module to contain the shared function `get_latest_ib_gib/2`.
  This function originates in the refresh.ex command module, and I want to use
  it in the allow.ex command module.

  I didn't think it belonged in helper.ex anywhere, because those functions are
  more small-ish functions, whereas `get_latest_ib_gib/2` is a higher-level
  ibGib function.
  """

  require Logger

  import IbGib.{Expression, Helper, QueryOptionsFactory}
  use IbGib.Constants, :ib_gib

  # ------------------------------------------------------------------
  # get_latest_ib_gib(identity_ib_gibs, src_ib_gib)
  # ------------------------------------------------------------------

  @doc """
  Gets the latest of any timelines starting with `src_ib_gib`. Usually this
  means it gets the "latest version" of the given `src_ib_gib`, but if it has
  branching timelines for the "same" ibGib, then it may choose from any of them.

  This queries off of the given `identity_ib_gibs`, but it creates the query
  related to the given `src_ib_gib`'s identities.
  """
  def get_latest_ib_gib(identity_ib_gibs, src_ib_gib) do
    with(
      # We will query off of the current identity
      {:ok, current_identity} <- IbGib.Expression.Supervisor.start_expression(Enum.at(identity_ib_gibs, 0)),

      # Our search for the latest version must be using the credentials of
      # **that** ibgib's identities, i.e. in that timeline.
      {:ok, src_ib_gib_process} <-
        IbGib.Expression.Supervisor.start_expression(src_ib_gib),
      {:ok, src_ib_gib_info} <- src_ib_gib_process |> get_info(),
      {:ok, src_ib_gib_identity_ib_gibs} <-
        get_ib_gib_identity_ib_gibs(src_ib_gib_info),

      # Build the query options
      {:ok, query_opts} <-
        build_query_opts_latest(src_ib_gib_identity_ib_gibs, src_ib_gib),

      # Execute the query itself, which creates the query_result ib_gib
      {:ok, query_result} <-
        current_identity |> query(identity_ib_gibs, query_opts),

        # Return the query_result result ib^gib
      {:ok, query_result_info} <- query_result |> get_info(),
      {:ok, result_ib_gib} <-
        extract_result_ib_gib(src_ib_gib, query_result_info)
    ) do
      {:ok, result_ib_gib}
    else
      error -> default_handle_error(error)
    end
  end

  def get_identities_for_query(identity_ib_gibs) do
    possibles = 
      identity_ib_gibs
      |> Enum.filter(&(&1 != @root_ib_gib))
      |> Enum.filter(&(!String.starts_with?(&1, "node")))
    if length(possibles) > 0 do
      {:ok, possibles}
    else
      {:error, "No queryable identities found. Must have at least one non-root and non-node identity."}
    end
  end
  
  defp build_query_opts_latest(identity_ib_gibs, ib_gib) do
    with(
      {:ok, identities_for_query} <-
        get_identities_for_query(identity_ib_gibs),
      query_opts = (
        do_query()
        |> where_rel8ns("identity", "withany", "ibgib", identities_for_query)
        |> where_rel8ns("past", "withany", "ibgib", [ib_gib])
        |> most_recent_only()
      )
    ) do
      {:ok, query_opts}
    end
  end

  defp get_ib_gib_identity_ib_gibs(ib_gib_info) do
    _ = Logger.debug("ib_gib_info:\n#{inspect ib_gib_info}" |> ExChalk.magenta)
    rel8ns = ib_gib_info[:rel8ns]
    _ = Logger.debug("rel8ns:\n#{inspect rel8ns}" |> ExChalk.magenta)
    identities = rel8ns["identity"]
    _ = Logger.debug("identities:\n#{inspect identities}" |> ExChalk.magenta)
    {:ok, identities}
  end

  defp extract_result_ib_gib(src_ib_gib, query_result_info) do
    result_data = query_result_info[:rel8ns]["result"]
    result_count = Enum.count(result_data)
    case result_count do
      1 ->
        # Not found (1 result is root), so the "latest" is the one that we're
        # search off of (has no past)
        {:ok, src_ib_gib}

      2 ->
        # First is always root, so get second
        {:ok, Enum.at(result_data, 1)}

      _ ->
        _ = Logger.error "unknown result count: #{result_count}"
        {:ok, @root_ib_gib}
    end
  end
end
