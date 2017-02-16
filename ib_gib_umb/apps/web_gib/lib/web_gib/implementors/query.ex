defmodule WebGib.Implementors.Query do
  @moduledoc """
  Right now, this is used in the query func of the ib_gib_controller.
  """

  # ----------------------------------------------------------------------------
  # Usings, imports, etc.
  # ----------------------------------------------------------------------------

  import Expat
  require Logger

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs
  use IbGib.Constants, :validation
  use WebGib.Constants, :error_msgs
  use WebGib.Constants, :keys
  use WebGib.Constants, :validation
  use WebGib.Constants, :config

  # alias IbGib.Transform.Mut8.Factory, as: Mut8Factory
  alias IbGib.{Expression, Auth.Identity}
  alias WebGib.Adjunct
  alias WebGib.Bus.Channels.Event, as: EventChannel
  import IbGib.{Helper, Macros, QueryOptionsFactory}
  import WebGib.{Gettext, Patterns, Router.Helpers, Validate}


  # I don't want to see the lint message for this right now. I'm aware that
  # the signature is just growing. But it's more concise than destructuring
  # the incoming params map.
  # @lint false
  # defp query_impl(conn, src_ib_gib, search_ib, ib_query_type, latest, search_data) do
  def query_impl(conn, query_params_(...) = query_params) do
    _ = Logger.debug "src_ib_gib: #{src_ib_gib}\nquery_params: #{inspect query_params}"

    with(
      # Identities (need plug)
      identity_ib_gibs <- 
        conn |> Plug.Conn.get_session(@ib_identity_ib_gibs_key),

      # We will query off of the given src
      {:ok, src} <- IbGib.Expression.Supervisor.start_expression(src_ib_gib),

      # Build the query options
      {:ok, query_opts} <-
        build_query_opts(identity_ib_gibs, query_params),

      # Execute the query itself, which creates the query_result ib_gib
      {:ok, query_result} <-
        src |> Expression.query(identity_ib_gibs, query_opts),

      # Return the query's ib^gib
      {:ok, query_result_info} <- query_result |> Expression.get_info,
      {:ok, query_result_ib_gib} <- get_ib_gib(query_result_info)
    ) do
      {:ok, query_result_ib_gib}
    else
      error -> default_handle_error(error)
    end
  end

  defp build_query_opts(identity_ib_gibs, query_params_(...) = query_params)
    when is_list(identity_ib_gibs) and
         length(identity_ib_gibs) > 1 do

    query_identities = get_query_identities(identity_ib_gibs)
    
    _ = Logger.debug("query_identities: #{inspect query_identities}" |> ExChalk.bg_green |> ExChalk.black)

    if ib_is? or ib_has? or data_has? or tag_is? or tag_has? do
      query_opts = nil

      # ib_is?
      query_opts = 
        query_opts
        |> add_ib_query_if_needed(query_identities, query_params)
        |> add_data_query_if_needed(query_identities, query_params)
        |> add_tag_query_if_needed(query_identities, query_params)

      _ = Logger.debug("query_opts: #{inspect query_opts}" |> ExChalk.bg_green |> ExChalk.black)

      {:ok, query_opts}
    else 
      {:error, "No query target is selected. You must choose to search at least one: ib is, ib has, data has, tag is, tag has."}
    end
  end
  defp build_query_opts(identity_ib_gibs, query_params) do
    invalid_args([identity_ib_gibs, query_params])
  end

  defp do_query_or_union(_query_opts = nil) do
    do_query()
  end
  defp do_query_or_union(query_opts) do
    query_opts |> union()
  end

  # ib --------------------------
  defp add_ib_query_if_needed(query_opts, 
                              query_identities, 
                              query_params_(...) = query_params) do
    _ = Logger.debug("query_opts: #{inspect query_opts}\nib_is?: #{ib_is?}\nib_has?: #{ib_has?}\nsearch_text: #{search_text}" |> ExChalk.bg_green |> ExChalk.black)
                          
    if (ib_is? or ib_has?) and 
       !is_nil(search_text) and 
       String.length(search_text) > 0 do
      query_opts
      |> do_query_or_union()
      |> add_ib_clause(query_params)
      |> add_identity_clause(query_identities)
      |> add_exclude_clauses(query_params)
      |> add_latest_clause(query_params)
    else
      query_opts
    end
  end

  defp add_ib_clause(query_opts, 
                     query_params_(
                      search_text: search_text, 
                      ib_is?: true, 
                      ib_has?: false
                    ) = _query_params) do
    query_opts 
    |> where_ib("is", search_text)
  end
  defp add_ib_clause(query_opts, 
                     query_params_(
                       search_text: search_text, 
                       ib_has?: true
                     ) = _query_params) do
    query_opts 
    |> where_ib("like", search_text)
  end
  defp add_ib_clause(query_opts, _query_params) do
    query_opts
  end

  # data -------------------------
  defp add_data_query_if_needed(query_opts, 
                                query_identities, 
                                query_params_(...) = query_params) do
    _ = Logger.debug("query_opts: #{inspect query_opts}\ndata_has?: #{data_has?}\nsearch_text: #{search_text}" |> ExChalk.bg_green |> ExChalk.black)
                          
    if data_has? and 
       !is_nil(search_text) and 
       String.length(search_text) > 0 do
      query_opts
      |> do_query_or_union()
      |> add_data_clause(query_params)
      |> add_identity_clause(query_identities)
      |> add_exclude_clauses(query_params)
      |> add_latest_clause(query_params)
    else
      query_opts
    end
  end
  
  defp add_data_clause(query_opts, 
                       query_params_(
                         search_text: search_text, 
                         data_has?: true 
                       ) = _query_params) do
    query_opts 
    |> where_data("value", "like", search_text)
  end
  defp add_data_clause(query_opts, _query_identities, _query_params) do
    query_opts
  end

  # tag --------------------------
  defp add_tag_query_if_needed(query_opts, 
                               query_identities, 
                               query_params_(...) = query_params) do
    _ = Logger.debug("query_opts: #{inspect query_opts}\ndata_has?: #{data_has?}\nsearch_text: #{search_text}" |> ExChalk.bg_green |> ExChalk.black)
                          
    if (tag_is? or tag_has?) and 
       !is_nil(search_text) and 
       String.length(search_text) > 0 do
      query_opts
      |> do_query_or_union()
      |> add_tag_clause(query_params)
      |> add_identity_clause(query_identities)
      |> add_exclude_clauses(query_params)
      |> add_latest_clause(query_params)
    else
      query_opts
    end
  end

  defp add_tag_clause(query_opts, 
                      query_params_(
                        search_text: search_text, 
                        tag_is?: true, 
                        tag_has?: false
                      ) = _query_params) do
    # Each tag's ib is in the form of "tag keyword1 keyword2 ..."
    # e.g. "tag bookmark", "tag flagged copyright", and so on.
    # When the tag is created, the keywords are always downcased.
    # e.g. "UberTag" => "ubertag"
    
    query_opts 
    |> where_rel8ns("tag", "with", "ib", "tag #{String.downcase(search_text)}")
  end
  # defp add_tag_clause(query_opts, 
  #                     query_params_(
  #                       search_text: search_text, 
  #                       tag_has?: true
  #                     ) = _query_params) do
  #   query_opts 
  #   # |> where_tag("like", search_text)
  # end
  defp add_tag_clause(query_opts, _query_params) do
    query_opts
  end

  # shared -----------------------

  defp add_identity_clause(query_opts = nil, _query_identities) do
    query_opts # nil
  end
  defp add_identity_clause(query_opts, query_identities) do
    query_opts 
    |> where_rel8ns("identity", "withany", "ibgib", query_identities)
  end

  defp get_query_identities(identity_ib_gibs) do
    # All queries (currently) look only within the current user's identities.
    # We're searching only for the user's ibgib, and we're going to do a
    # "withany" query. If we kept in the root, then it would return everything
    # since everybody has the root in its identity_ib_gibs. 
    # We also don't want any node identities in the query. We're looking only
    # for session and email identities.
    identity_ib_gibs
    |> Enum.filter(&(&1 != @root_ib_gib))
    |> Enum.filter(fn(identity_ib_gib) -> 
         {ib, _gib} = separate_ib_gib!(identity_ib_gib)
         [type, _hash] = String.split(ib, "_")
         type !== "node" 
       end)
  end

  # Driven by the include_x? query_params.
  defp add_exclude_clauses(query_opts, 
                           query_params_(...) = query_params) do
    query_opts
    |> add_exclude_ancestor_clause(include_pic?, 
                                   ["pic#{@delim}gib"])
    |> add_exclude_ancestor_clause(include_comment?,
                                   ["comment#{@delim}gib"])
    |> add_exclude_ancestor_clause(include_query?,
                                   ["query#{@delim}gib",
                                    "query_result#{@delim}gib"])
    |> add_exclude_ancestor_clause(include_dna?, 
                                   ["plan#{@delim}gib",
                                    "fork#{@delim}gib",
                                    "mut8#{@delim}gib",
                                    "rel8#{@delim}gib"])
    |> add_exclude_ancestor_clause(include_tag?, 
                                   ["tag#{@delim}gib"])
  end
  
  # If include? true, then return query_opts. If false, exclude them.
  defp add_exclude_ancestor_clause(query_opts, _include? = true, ib_gibs) do
    query_opts
  end
  defp add_exclude_ancestor_clause(query_opts, _include? = false, ib_gibs) do
    # I don't have "withoutany" implemented for rel8n, so adding multiple 
    # "without" clauses to exclude each ib_gib.
    ib_gibs 
    |> Enum.reduce(query_opts, fn(ib_gib, acc) -> 
         acc |> where_rel8ns("ancestor", "without", "ibgib", ib_gib)
       end)
  end

  defp add_latest_clause(query_opts, 
                         query_params_(
                           latest?: true
                         ) = _query_params) do
    query_opts 
    |> most_recent_only()
  end
  defp add_latest_clause(query_opts, _query_params) do
    query_opts
  end
  
end
