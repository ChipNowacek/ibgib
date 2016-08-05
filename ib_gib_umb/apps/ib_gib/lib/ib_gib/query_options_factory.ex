defmodule IbGib.QueryOptionsFactory do
  alias IbGib.Helper
  use IbGib.Constants, :ib_gib

  # I would prefer to have this in IbGib.Constants, but I can't figure out
  # how to put it in the guard.
  @ib_search_methods ["is", "in", "regex"]
  defmacro is_valid_ib_method(method) do
    quote do: unquote(method) in @ib_search_methods
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
end
