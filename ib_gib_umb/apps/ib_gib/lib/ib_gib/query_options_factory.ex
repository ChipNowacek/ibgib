defmodule IbGib.QueryOptionsFactory do
  @moduledoc """
  This module provides factory functions to build queries to pass to the
  `IbGib.Expression.query/2` function.

  See `IbGib.Expression.ExpressionQueryTest` for examples on how to use it.
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

  @with_or_without ["with", "without"]
  defmacro is_valid_with_or_without(with_or_without) do
    quote do: unquote(with_or_without) in @with_or_without
  end

  @key_and_or_value ["key", "value", "keyvalue"]
  defmacro is_valid_key_and_or_value(arg) do
    quote do: unquote(arg) in @key_and_or_value
  end

  @doc """
  Creates an initial query clause with no query constraints.
  Each subsequent call is considered an AND where constraint (or order_by).

  If you want to union with another query statement, use `or/1`.
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

    Map.put(acc_options, next_key, options)
  end

  def where_ib(acc_options, method, search_term)
    when is_map(acc_options) and is_bitstring(search_term) and
         is_bitstring(method) and is_valid_ib_method(method) do

    Logger.warn "acc_options: #{inspect acc_options}"

    current_key = "#{map_size(acc_options)}"
    current_options = acc_options[current_key]
    current_details = current_options["ib"]
    if map_size(current_details) > 0 do
      Logger.warn "Tried to do more than one where ib statement"
    end

    Logger.warn "current_key: #{current_key}"
    Logger.warn "current_options: #{inspect current_options}"
    Logger.warn "current_details: #{inspect current_details}"

    this_details = %{
      "what" => search_term,
      "how" => method
    }

    Logger.warn "this_details: #{inspect this_details}"
    current_options = Map.put(current_options, "ib", this_details)

    # result = Map.merge(acc_options, %{"ib" => ib_options})
    # for the current query union clause
    result = Map.put(acc_options, current_key, current_options)

    Logger.warn "result of where_ib: #{inspect result}"
    result
  end

  def where_gib(acc_options, method, search_term)
    when is_map(acc_options) and is_bitstring(search_term) and
         is_bitstring(method) and is_valid_ib_method(method) do

    options = %{
      "gib" => %{
        "what" => search_term,
        "how" => method
      }
    }
    # %{
    #    "1" => %{
    #     "ib" => ib_options,
    #     "gib" => gib_options,
    #     "data" => data_options,
    #     "rel8ns" => rel8ns_options,
    #     "time" => time_options,
    #     "meta" => meta_options
    #   }
    # }

    # Overrides the "gib" section of the accumulated options
    # for the current query union clause
    current_key = map_size(acc_options)
    current_options = acc_options[current_key]
    current_options = Map.merge(current_options, options)
    Map.put(acc_options, current_key, current_options)
  end

  def where_data(acc_options, where, method, search_term)
    when is_map(acc_options) and is_bitstring(search_term) and
         is_bitstring(method) and is_valid_data_method(method) and
         is_bitstring(where) and is_valid_key_and_or_value(where) do
    options = %{
      "data" => %{
        "what" => search_term,
        "how" => method,
        "where" => where
      }
    }

    # Overrides the "data" section of the accumulated options
    # for the current query union clause
    current_key = map_size(acc_options)
    current_options = acc_options[current_key]
    current_options = Map.merge(current_options, options)
    Map.put(acc_options, current_key, current_options)
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
  def where_rel8ns(acc_options, rel8n_name, with_or_without, method, search_term)
    when is_map(acc_options) and is_bitstring(rel8n_name) and
         is_valid_with_or_without(with_or_without) and
         is_valid_rel8ns_method(method) and is_bitstring(search_term) do
    options = %{
      "rel8ns" => %{
        "where" => rel8n_name,
        "extra" => with_or_without,
        "how" => method,
        "what" => search_term,
      }
    }

    # Overrides the "rel8ns" section of the accumulated options
    current_key = map_size(acc_options)
    current_options = acc_options[current_key]
    current_options = Map.merge(current_options, options)
    Map.put(acc_options, current_key, current_options)
  end

  def most_recent_only(acc_options) do
    options = %{
      "time" => %{
        "how" => "most recent"
      }
    }

    # Overrides the "time" section of the accumulated options
    current_key = map_size(acc_options)
    current_options = acc_options[current_key]
    current_options = Map.merge(current_options, options)
    Map.put(acc_options, current_key, current_options)
  end

end
