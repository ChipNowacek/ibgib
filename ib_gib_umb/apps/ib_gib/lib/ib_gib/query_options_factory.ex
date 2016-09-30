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


  # ----------------------------------------------------------------------------
  # Macros (used in guards)
  # ----------------------------------------------------------------------------

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
    _ = Logger.debug "union result: #{inspect result}"
    result
  end

  # ----------------------------------------------------------------------------
  # Add details
  # where clauses, time
  # ----------------------------------------------------------------------------

  @doc """
  Use this to add a where clause regarding the `IbGib.Data.Schemas.IbGibModel` `ib` field.

  ## Examples

  where_ib("is", "some IB here 1234")

  # Implicit `%`s
  where_ib("like", "IB here")
    # which is equivalent to
  where_ib("like", "%IB here%")

  # Explicit `%`s
  where_ib("like", "s%here%")

  See `IbGib.Expression.ExpressionQueryTest` for more examples.
  """
  def where_ib(acc_options, method, search_term)
    when is_map(acc_options) and is_bitstring(search_term) and
         is_bitstring(method) and is_valid_ib_method(method) do

    {current_key, current_options, _current_details} =
      get_current(acc_options, "ib")


    this_details = %{
      "what" => search_term,
      "how" => method
    }

    insert_details(acc_options, current_key, current_options, "ib", this_details)
  end

  @doc """
  Adds a where clause to test if a `gib` "is" or "like" a given `search_term`.

  ## Examples

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

    {current_key, current_options, _current_details} =
      get_current(acc_options, "gib")

    this_details = %{
      "what" => search_term,
      "how" => method
    }

    insert_details(acc_options, current_key, current_options, "gib", this_details)
  end

  @doc """
  The `IbGib.Data.Schemas.IbGibModel` has a map property for `data`.
  This is a key/value map, so the `where_data/4` function can query
  against that map.

  ## Examples

    ### data keys
    where_data("key", "is", "some key here")

    # Implicit `%`s
    where_data("key", "like", "ome ke")
      which is equivalent to
    where_data("key", "like", "%ome ke%")

    # Explicit `%`s
    where_data("key", "like", "s%key here")
    where_data("key", "like", "s%key here")
    where_data("key", "like", "s%k%h%e")

    ### data values (ATOW 2016/09/02 the same as keys, just pass "value")
    where_data("value", "is", "some value here")

    # Implicit `%`s
    where_data("value", "like", "ome va")
      which is equivalent to
    where_data("value", "like", "%ome va%")

    # Explicit `%`s
    where_data("value", "like", "s%value here")
    where_data("value", "like", "s%value here")
    where_data("value", "like", "s%v%h%e")
  """
  def where_data(acc_options, where, method, search_term)
    when is_map(acc_options) and is_bitstring(search_term) and
         is_bitstring(method) and is_valid_data_method(method) and
         is_bitstring(where) and is_valid_key_and_or_value(where) do
    {current_key, current_options, _current_details} =
      get_current(acc_options, "data")

    this_details = %{
      "what" => search_term,
      "how" => method,
      "where" => where
    }

    insert_details(acc_options, current_key, current_options, "data", this_details)
  end

  @doc """
  Rel8ns are at the heart of all ib_gib. This is how "prototype aggregation"
  is implemented. In an OOP language, or even a data struct in an FP language,
  you might add a property in some sort of declaration file.

  In IbGib, this act of you, the developer, "adding" a property thing is
  captured in "code/data" via a rel8n. Say for instance, you have created two
  ib_gib: "Shape" and "Color", with the `ib^gib` being something like
  "Shape^S1" and "Color^C1". You could "attach" the color to the shape
  via a rel8n in multiple ways. If you were creating a Shape class, you could
  add a rel8n like (pseudo-code)`shape.rel8(color, "property")` which would
  create a new Shape, "Shape^S2" with one of its rel8ns now "property" =>
  ["Color^GIB345"]. Or perhaps you could do it more organically by simply
  calling the rel8n "color", e.g. "color" => ["Color^GIB345"]. So now, the Shape
  ib_gib is rel8d to the color ib_gib and will be going forward in "time".

  To search for ib_gib with these rel8ns, we can provide either just the `ib`,
  or the full `ib^gib`.

  Also, rel8ns can be ANDed in queries (this is not implemented yet for data
  ATOW 2016/09/02). So you can add multiple rel8n query where clauses.

  ## Examples
    query_opts =
      do_query
      |> where_rel8ns("property", "with", "ibgib", "Color^C1")

    query_opts =
      do_query
      |> where_rel8ns("property", "with", "ibgib", "Color^C1")
      |> where_rel8ns("identity", "with", "ibgib", "cool usernameish ib^ibGib_SOMEGIB1234_ibGib")

    query_opts =
      do_query
      |> where_rel8ns("color", "with", "ibgib", "Color^C1")

    query_opts =
      do_query
      |> where_rel8ns("property", "with", "ib", "Color")

    query_opts =
      do_query
      |> where_rel8ns("ancestor", "with", "ibgib", "some ib^SOMEGIB1234")

    query_opts =
      do_query
      |> where_rel8ns("identity", "with", "ibgib", "cool usernameish ib^ibGib_SOMEGIB1234_ibGib")

    query_opts =
      do_query
      |> where_rel8ns("ancestor", "without", "ibgib", "some ib^SOMEGIB1234")

    query_opts =
      do_query
      |> where_rel8ns("ancestor", "with", "ib", "some ib here")
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
      _ = Logger.error("Invalid search_term_list: #{inspect search_term_list}")
      acc_options
    end
  end

  @doc """
  Get only the most recent result. This is equivalent to
  sorting by `inserted_at` and limiting to 1.
  """
  def most_recent_only(acc_options) do
    {current_key, current_options, _current_details} =
      get_current(acc_options, "time")

    this_details = %{
      "how" => "most recent"
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
    _ = Logger.debug "acc_options: #{inspect acc_options}"
    current_key = "#{map_size(acc_options)}"
    current_options = acc_options[current_key]
    current_details = current_options[category]
    if map_size(current_details) > 0 do
      _ = Logger.warn "Tried to do more than one where data statement"
    end

    # _ = Logger.debug "current_key: #{current_key}"
    # _ = Logger.debug "current_options: #{inspect current_options}"
    # _ = Logger.debug "current_details: #{inspect current_details}"

    {current_key, current_options, current_details}
  end

  defp insert_details(acc_options, current_key, current_options, category, details) do
    _ = Logger.debug "details: #{inspect details}"
    current_options = Map.put(current_options, category, details)

    # result = Map.merge(acc_options, %{"ib" => ib_options})
    # for the current query union clause
    result = Map.put(acc_options, current_key, current_options)

    _ = Logger.debug "result of insert_details: #{inspect result}"
    result
  end


end
