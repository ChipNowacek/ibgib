defmodule IbGib.TransformFactory do
  alias IbGib.Helper
  use IbGib.Constants, :ib_gib

  @doc """
  Creates a fork with source `src_ib_gib` and dest_ib of given `dest_ib`. In
  most cases, no `dest_ib` need be specified, so it will just create a new
  random `ib`.
  """
  @spec fork(String.t, String.t) :: map
  def fork(src_ib_gib \\ "ib#{delim}gib", dest_ib \\ Helper.new_id) when is_bitstring(src_ib_gib) and is_bitstring(dest_ib) do
    ib = "fork"
    relations = %{
      "history" => ["ib#{delim}gib", "fork#{delim}gib"]
    }
    data = %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib}
    gib = Helper.hash(ib, relations, data)
    %{
      ib: ib,
      gib: gib,
      rel8ns: relations,
      data: data
    }
  end

  @doc """
  Creates a mut8 transform that will mut8 the internal `data` map of the given
  `src_ib_gib`. This will perform a merge of the given `new_data` map onto the
  existing `data` map, replacing any identical keys.
  """
  @spec mut8(String.t, map) :: map
  def mut8(src_ib_gib, new_data) when is_bitstring(src_ib_gib) and is_map(new_data) do
    ib = "mut8"
    relations = %{
      "history" => ["ib#{delim}gib", "mut8#{delim}gib"]
    }
    data = %{"src_ib_gib" => src_ib_gib, "new_data" => new_data}
    gib = Helper.hash(ib, relations, data)
    %{
      ib: ib,
      gib: gib,
      rel8ns: relations,
      data: data
    }
  end

  @default_rel8ns ["rel8d"]

  @doc """
  Creates a rel8 transform that will rel8 the given `src_ib_gib` to the given
  `dest_ib_gib` according to details in given `how` map.

  It is expecting `how` to include at least keys called src_rel8n and dest_rel8n
  which describe `how` the `src_ib_gib` is related to the `dest_ib_gib`.
  `src_rel8n` will add a relation to the src with this name of the rel8n, and
  `dest-rel8n` will add a relation to the dest.
  """
  @spec rel8(String.t, String.t, list(String.t), list(String.t)) :: map
  def rel8(src_ib_gib, dest_ib_gib, src_rel8ns \\ @default_rel8ns, dest_rel8ns \\ @default_rel8ns)
    when is_bitstring(src_ib_gib) and is_bitstring(dest_ib_gib) and
         src_ib_gib !== dest_ib_gib and
         src_ib_gib !== "ib#{@delim}gib" and dest_ib_gib !== "ib#{@delim}gib" and
         is_list(src_rel8ns) and length(src_rel8ns) >= 1 and
         is_list(dest_rel8ns) and length(dest_rel8ns) >= 1  do
    ib = "rel8"
    relations = %{
      "history" => ["ib#{delim}gib", "rel8#{delim}gib"]
    }
    data = %{
      "src_ib_gib" => src_ib_gib,
      "dest_ib_gib" => dest_ib_gib,
      "src_rel8ns" => src_rel8ns |> Enum.concat(@default_rel8ns) |> Enum.uniq,
      "dest_rel8ns" => dest_rel8ns |> Enum.concat(@default_rel8ns) |> Enum.uniq
    }
    gib = Helper.hash(ib, relations, data)
    %{
      ib: ib,
      gib: gib,
      rel8ns: relations,
      data: data
    }
  end

  def query(query_options)
    when is_map(query_options) do

    ib = "query"
    relations = %{
      "history" => ["ib#{delim}gib", "query#{delim}gib"]
    }
    data = %{
      "options" => query_options
    }
    gib = Helper.hash(ib, relations, data)
    %{
      ib: ib,
      gib: gib,
      rel8ns: relations,
      data: data
    }
  end
end
