defmodule IbGib.TransformFactory do
  alias IbGib.Helper

  @delim "^"

  @doc """
  Creates a fork with source `src_ib_gib` and dest_ib of given `dest_ib`. In
  most cases, no `dest_ib` need be specified, so it will just create a new
  random `ib`.
  """
  @spec fork(String.t, String.t) :: map
  def fork(src_ib_gib \\ "ib#{@delim}gib", dest_ib \\ Helper.new_id) when is_bitstring(src_ib_gib) and is_bitstring(dest_ib) do
    ib = "fork"
    relations = %{
      "history" => ["ib#{@delim}gib", "fork#{@delim}gib"]
    }
    data = %{src_ib_gib: src_ib_gib, dest_ib: dest_ib}
    gib = Helper.hash(ib, relations, data)
    %{
      ib: ib,
      gib: gib,
      relations: relations,
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
      "history" => ["ib#{@delim}gib", "mut8#{@delim}gib"]
    }
    data = %{src_ib_gib: src_ib_gib, new_data: new_data}
    gib = Helper.hash(ib, relations, data)
    %{
      ib: ib,
      gib: gib,
      relations: relations,
      data: data
    }
  end
end
