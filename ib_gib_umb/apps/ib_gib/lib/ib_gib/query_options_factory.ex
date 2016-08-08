defmodule IbGib.QueryOptionsFactory do
  require Logger

  alias IbGib.Helper
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

  @rel8ns_search_methods ["ib", "ib_gib"]
  defmacro is_valid_rel8ns_method(method) do
    quote do: unquote(method) in @rel8ns_search_methods
  end

  @with_or_without ["with", "without"]
  defmacro is_valid_with_or_without(with_or_without) do
    quote do: unquote(with_or_without) in @with_or_without
  end

  @key_and_or_value ["key", "value", "keyvalue"] #, "regex"] not implemented yet
  defmacro is_valid_key_and_or_value(arg) do
    quote do: unquote(arg) in @key_and_or_value
  end

  def do_query() do
    %{
      "ib" => %{},
      "data" => %{},
      "rel8ns" => %{},
      "time" => %{},
      "meta" => %{}
    }
  end

  def where_ib(acc_options, method, search_term)
    when is_map(acc_options) and is_bitstring(search_term) and
         is_bitstring(method) and is_valid_ib_method(method) do

    options = %{
      "ib" => %{
        "what" => search_term,
        "how" => method
      }
    }
    # %{
    #   "ib" => ib_options,
    #   "data" => data_options,
    #   "rel8ns" => rel8ns_options,
    #   "time" => time_options,
    #   "meta" => meta_options
    # }

    # Overrides the "ib" section of the accumulated options
    Map.merge(acc_options, options)
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
    Map.merge(acc_options, options)
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
    Map.merge(acc_options, options)
  end

end
