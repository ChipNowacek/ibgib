defmodule IbGib.QueryOptionsFactory do
  @moduledoc """
  This module provides factory functions to build queries to pass to the
  `IbGib.Expression.query/2` function.

  * See `IbGib.Expression.ExpressionQueryTest` for examples on how to use it.
  * See `IbGib.Data` to see where these are finally consumed in the data
  access layer.
  """
  require Logger

  use IbGib.Constants, :ib_gib

  # I would prefer to have this in IbGib.Constants, but I can't figure out
  # how to put it in the guard.
  @ib_search_methods ["is", "like", "isnt"] #, "regex"] not implemented yet
  defmacro is_valid_ib_method(method) do
    quote do: unquote(method) in @ib_search_methods
  end

  @data_search_methods ["is", "like"] #, "regex"] not implemented yet
  defmacro is_valid_data_method(method) do
    quote do: unquote(method) in @data_search_methods
  end

  @rel8ns_search_methods ["ib", "ibgib"]
  defmacro is_valid_rel8ns_method(method) do
    quote do: unquote(method) in @rel8ns_search_methods
  end

  @rel8n_query_type ["with", "without", "withany"]
  defmacro is_valid_rel8n_query_type(rel8n_query_type) do
    quote do: unquote(rel8n_query_type) in @rel8n_query_type
  end

  @key_and_or_value ["key", "value", "keyvalue"]
  defmacro is_valid_key_and_or_value(arg) do
    quote do: unquote(arg) in @key_and_or_value
  end


  # ----------------------------------------------------------------------------
  # Common
  # do_query, union
  # ----------------------------------------------------------------------------

  @doc """
  Creates an initial query clause with no query constraints.
  Executing this would get all ib_gib in the entire persistence store.

  Each subsequent piped fluent call is considered an AND where constraint
  (or order_by). If you want to union with another query statement, use `union/1`.
  """
  def do_query() do
    %{
      "1" =>
        %{
          "ib" => %{},
          "gib" => %{},
          "data" => %{},
          "rel8ns" => %{},
          "time" => %{},
          "meta" => %{}
        }
    }
  end

  @doc """
  Adds another query clause that will be unioned to the previous clause(s).
  """
  def union(acc_options) do
    next_key = map_size(acc_options) + 1

    options =
      %{
        "ib" => %{},
        "gib" => %{},
        "data" => %{},
        "rel8ns" => %{},
        "time" => %{},
        "meta" => %{}
      }

    result = Map.put(acc_options, "#{next_key}", options)
    Logger.debug "union result: #{inspect result}"
    result
  end

  # ----------------------------------------------------------------------------
  # Add details
  # where clauses, time
  # ----------------------------------------------------------------------------

  def where_ib(acc_options, method, search_term)
    when is_map(acc_options) and is_bitstring(search_term) and
         is_bitstring(method) and is_valid_ib_method(method) do

    {current_key, current_options, current_details} =
      get_current(acc_options, "ib")


    this_details = %{
      "what" => search_term,
      "how" => method
    }

    insert_details(acc_options, current_key, current_options, "ib", this_details)
  end

  @doc """
  Adds a where clause to test if a `gib` "is" or "like" a given `search_term`.

  E.g.
    where_gib("is", "someGIBhere1234")

    # Implicit `%`s
    where_gib("like", "GIBhere")
      which is equivalent to
    where_gib("like", "%GIBhere%")

    # Explicit `%`s
    where_gib("like", "s%here%")
  """
  def where_gib(acc_options, method, search_term)
    when is_map(acc_options) and is_bitstring(search_term) and
         is_bitstring(method) and is_valid_ib_method(method) do

    {current_key, current_options, current_details} =
      get_current(acc_options, "gib")

    this_details = %{
      "what" => search_term,
      "how" => method
    }

    insert_details(acc_options, current_key, current_options, "gib", this_details)
  end

  @doc """

  """
  def where_data(acc_options, where, method, search_term)
    when is_map(acc_options) and is_bitstring(search_term) and
         is_bitstring(method) and is_valid_data_method(method) and
         is_bitstring(where) and is_valid_key_and_or_value(where) do
    {current_key, current_options, current_details} =
      get_current(acc_options, "data")

    this_details = %{
      "what" => search_term,
      "how" => method,
      "where" => where
    }

    insert_details(acc_options, current_key, current_options, "data", this_details)
  end

  @doc """
  Search for ib_gib with rel8ns to a given `ib` or `ib_gib`.
  For example, if a user's ib_gib is `bob^ABCD` and you want a query of
  all of the user's ib_gib, then the `rel8n_name` should be `"user"`, method
  should be `"ib_gib"` and the `search_term` should be `bob^ABCD`. (I think, I
  haven't implemented "user" just yet but that is the plan.)

  `method` is either `"ib"` or `"ib_gib"`
  `search_term` should be either a valid ib or valid ib_gib:
  e.g. "some ib here", or "some ib here^SOMEHASH01982347fkj"
  """
  def where_rel8ns(acc_options, rel8n_name, rel8n_query_type, method, search_term)
  # This overload is for bitstring search terms
  def where_rel8ns(acc_options, rel8n_name, rel8n_query_type, method, search_term)
    when is_map(acc_options) and is_bitstring(rel8n_name) and
         is_valid_rel8n_query_type(rel8n_query_type) and
         is_valid_rel8ns_method(method) and
         is_bitstring(search_term) do

    {current_key, current_options, current_details} =
      get_current(acc_options, "rel8ns")

    current_details_size = map_size(current_details)
    details_key = "#{current_details_size + 1}"
    this_details = %{
      "where" => rel8n_name,
      "extra" => rel8n_query_type,
      "how" => method,
      "what" => search_term,
    }
    new_details = current_details |> Map.put(details_key, this_details)

    insert_details(acc_options, current_key, current_options, "rel8ns", new_details)
  end
  # This overload is for list(bitstring) search terms
  def where_rel8ns(acc_options, rel8n_name, rel8n_query_type, method, search_term_list)
    when is_map(acc_options) and is_bitstring(rel8n_name) and
         is_valid_rel8n_query_type(rel8n_query_type) and
         is_valid_rel8ns_method(method) and
         is_list(search_term_list) do

    if Enum.all?(search_term_list, &(is_bitstring(&1))) do
      {current_key, current_options, current_details} =
        get_current(acc_options, "rel8ns")

      current_details_size = map_size(current_details)
      details_key = "#{current_details_size + 1}"
      this_details = %{
        "where" => rel8n_name,
        "extra" => rel8n_query_type,
        "how" => method,
        "what" => search_term_list,
      }
      new_details = current_details |> Map.put(details_key, this_details)

      insert_details(acc_options, current_key, current_options, "rel8ns", new_details)
    else
      # Not all search terms are bitstrings, so it's an invalid call
      # Just return the accumulated options
      Logger.error("Invalid search_term_list: #{inspect search_term_list}")
      acc_options
    end
  end

  def most_recent_only(acc_options) do
    {current_key, current_options, current_details} =
      get_current(acc_options, "time")

    this_details = %{
      # "time" => %{
        "how" => "most recent"
      # }
    }

    insert_details(acc_options, current_key, current_options, "time", this_details)
  end

  # ----------------------------------------------------------------------------
  # Helper
  # ----------------------------------------------------------------------------

  # All of these fluent factory functions have the same basic structure.
  # This part extracts the current stuff out of the accumulated options
  # (`acc_options`).
  defp get_current(acc_options, category) do
    Logger.warn "acc_options: #{inspect acc_options}"
    current_key = "#{map_size(acc_options)}"
    current_options = acc_options[current_key]
    current_details = current_options[category]
    if map_size(current_details) > 0 do
      Logger.warn "Tried to do more than one where data statement"
    end

    Logger.warn "current_key: #{current_key}"
    Logger.warn "current_options: #{inspect current_options}"
    Logger.warn "current_details: #{inspect current_details}"

    {current_key, current_options, current_details}
  end

  defp insert_details(acc_options, current_key, current_options, category, details) do
    Logger.warn "details: #{inspect details}"
    current_options = Map.put(current_options, category, details)

    # result = Map.merge(acc_options, %{"ib" => ib_options})
    # for the current query union clause
    result = Map.put(acc_options, current_key, current_options)

    Logger.warn "result of insert_details: #{inspect result}"
    result
  end


end
