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

  import OK, only: ["~>>": 2]
  require Logger
  require OK

  import IbGib.{Expression, Helper, QueryOptionsFactory}
  import IbGib.Macros, only: [invalid_args: 1, handle_ok_error: 2]
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

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
  def get_latest_ib_gib(_identity_ib_gibs, src_ib_gib = @root_ib_gib) do
    {:ok, @root_ib_gib}
  end
  def get_latest_ib_gib(identity_ib_gibs, src_ib_gib) 
    when is_list(identity_ib_gibs) and length(identity_ib_gibs) > 0 do
    OK.with do
      # We will query off of the current identity (1st, arbitrarily)
      current_identity <-
        identity_ib_gibs 
        |> Enum.at(0) 
        |> IbGib.Expression.Supervisor.start_expression()

      # Our search for the latest version must be using the credentials of
      # **that** ibgib's identities, i.e. in that timeline.
      src_ib_gib_identity_ib_gibs <- 
        {:ok, src_ib_gib}
        ~>> IbGib.Expression.Supervisor.start_expression()
        ~>> get_info()
        ~>> get_rel8ns("identity", [error_on_not_found: true])

      # Build the query options
      query_opts <-
        build_query_opts_latest(src_ib_gib_identity_ib_gibs, src_ib_gib)

      # Execute the query itself and pull the result_ib_gib out.
      result_ib_gib <-
        {:ok, current_identity} 
        ~>> query(identity_ib_gibs, query_opts)
        ~>> get_info()
        ~>> extract_result_ib_gib(src_ib_gib)

      OK.success result_ib_gib 
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end
  def get_latest_ib_gib(identity_ib_gibs, src_ib_gib) do
    invalid_args([identity_ib_gibs, src_ib_gib])
  end

  @doc """
  Takes a list of `ib_gibs`, and filters each ibGib timeline to its present
  ib_gib (relative latest for each ibGib).
  
  For example, say you have a list of 10 ib_gibs (ib^gib pointers). These
  aren't necessarily 10 different ibGib (timelines), but rather 10 pointers to
  n<=10 ibGibs. This could actually be a list of only a single ibGib with 9
  past pointers and 1 present pointer. Or it could be 2 ibGibs with 4 past
  ib_gibs each and 1 present ib_gib.
  
  ## Algorithm
  
  This will start with an empty accumulator list. The purpose is to fill this 
  list with the latest, unique ib^gibs from the starting list.
  
  It does this by pattern matching out the head ib^gib and getting its latest
  ib^gib. It will add this to the accumulator, and then it will check this 
  ib^gib's "past" rel8n. It will remove all of these from the next iteration's
  source list, thus eliminating the ibGib's entire timeline and storing that
  ibGib's most recent in the accumulator. It then executes this recursively
  until the entire `ib_gibs` list is exhausted.
  
  ## WARNING - Not optimized for scale
  
  This probably won't scale well and there is probably a way to do it strictly
  within PostgreSQL (I already know of at least one way in raw SQL). For now 
  tho (ATOW 2017/03/16), this is what I'm doing. :-)
  """
  @spec filter_present_only(list(String.t), list(String.t)) :: 
          {:ok, list(String.t)} | {:error, any}
  def filter_present_only(ib_gibs, _identity_ib_gibs) when ib_gibs === [] do
    {:ok, []}
  end
  def filter_present_only(ib_gibs, _identity_ib_gibs) 
    when ib_gibs === [@root_ib_gib] do
    {:ok, [@root_ib_gib]}
  end
  def filter_present_only(ib_gibs, identity_ib_gibs) when is_list(ib_gibs) do
    filter_present_iteration(ib_gibs, identity_ib_gibs, [])
  end
  def filter_present_only(ib_gibs, identity_ib_gibs) do
    invalid_args([ib_gibs, identity_ib_gibs])
  end
  
  defp filter_present_iteration([], _identity_ib_gibs, acc) 
    when is_list(acc) do
    # It's possible that there are duplicates in acc, so de-dupe.
    {:ok, acc |> Enum.uniq }
  end
  defp filter_present_iteration([ib_gib | rest], identity_ib_gibs, acc) 
    when is_list(acc) do
    OK.with do
      # Get the latest and add it to the accumulator
      latest_ib_gib <- get_latest_ib_gib(identity_ib_gibs, ib_gib)
      acc = acc ++ [latest_ib_gib]

      # Get all past ib^gibs and remove them from the next iteration
      latest_info <-
        IbGib.Expression.Supervisor.start_expression(latest_ib_gib) 
        ~>> get_info()
      past_ib_gibs <-
        get_rel8ns(latest_info, "past", [error_on_not_found: true])
      next =
        Enum.filter(rest, &(!Enum.member?(past_ib_gibs, &1)))
      
      filter_present_iteration(next, identity_ib_gibs, acc)
    end
  end
  defp filter_present_iteration(ib_gibs, identity_ib_gibs, acc) do
    invalid_args([identity_ib_gibs, ib_gibs, acc])
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

  @doc """
  Gets the identity_ib_gibs out of the given `ib_gib_info` map.
  
  Returns tagged identity ib^gibs.
  """
  def get_identity_ib_gibs(ib_gib_info) when is_map(ib_gib_info) do
    OK.with do
      identities <-
        get_rel8ns(ib_gib_info, "identity", [error_on_not_found: true])
      identities <-
        if identities !== [] do
          {:ok, identities}
        else
          {:error, "No identity rel8ns found"}
        end
      
      OK.success identities
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end
  def get_identity_ib_gibs(ib_gib_info) do
    invalid_args(ib_gib_info)
  end

  defp extract_result_ib_gib(query_result_info, default_ib_gib) do
    OK.with do
      result_data <- 
        get_rel8ns(query_result_info, "result", [error_on_not_found: true])
      result_count = Enum.count(result_data)
      case result_count do
        1 ->
          # Not found (1 result is root), so the "latest" is the one that we're
          # search off of (has no past)
          {:ok, default_ib_gib}

        2 ->
          # First is always root, so get second
          {:ok, Enum.at(result_data, 1)}

        _ ->
          _ = Logger.error "unknown result count: #{result_count}"
          {:ok, @root_ib_gib}
      end
    end
    # result_data = query_result_info[:rel8ns]["result"]
    # result_count = Enum.count(result_data)
    # case result_count do
    #   1 ->
    #     # Not found (1 result is root), so the "latest" is the one that we're
    #     # search off of (has no past)
    #     {:ok, default_ib_gib}
    # 
    #   2 ->
    #     # First is always root, so get second
    #     {:ok, Enum.at(result_data, 1)}
    # 
    #   _ ->
    #     _ = Logger.error "unknown result count: #{result_count}"
    #     {:ok, @root_ib_gib}
    # end
  end
end
