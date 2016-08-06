defmodule IbGib.QueryOptionsFactory do
  alias IbGib.Helper
  use IbGib.Constants, :ib_gib

  # I would prefer to have this in IbGib.Constants, but I can't figure out
  # how to put it in the guard.
  @ib_search_methods ["is", "like"] #, "regex"] not implemented yet
  defmacro is_valid_ib_method(method) do
    quote do: unquote(method) in @ib_search_methods
  end

  @data_search_methods ["is", "like"] #, "regex"] not implemented yet
  defmacro is_valid_data_method(method) do
    quote do: unquote(method) in @data_search_methods
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

    # Overrides the "ib" section of the
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

    # Overrides the "ib" section of the
    Map.merge(acc_options, options)
  end
end
