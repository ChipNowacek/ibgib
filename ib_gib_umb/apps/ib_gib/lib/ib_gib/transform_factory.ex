defmodule IbGib.TransformFactory do
  @moduledoc """
  This factory module generates ib_gib info maps for the fundamental transforms:
  fork, mut8, rel8, and query.

  These functions are used by the `IbGib.Expression` module itself, so ATOW
  (2016/08/20) no other consumers need to use these.
  """

  require Logger

  alias IbGib.Helper
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :transforms

  @default_rel8ns ["rel8d"]

  @doc """
  Creates a fork with source `src_ib_gib` and dest_ib of given `dest_ib`. In
  most cases, no `dest_ib` need be specified, so it will just create a new
  random `ib`.
  """
  @spec fork(String.t, String.t) :: map
  def fork(src_ib_gib \\ "ib#{delim}gib",
           dest_ib \\ Helper.new_id,
           opts \\ @default_transform_options)
    when is_bitstring(src_ib_gib) and is_bitstring(dest_ib) and is_map(opts) do
    Logger.debug "opts: #{inspect opts}"
    ib = "fork"
    relations = %{
      "dna" => ["ib#{delim}gib", "fork#{delim}gib"]
    }
    data = %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib}
    gib = Helper.hash(ib, relations, data) |> stamp_if_needed(opts[:gib_stamp])
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

  If `opts` :gib_stamp is true, then we will "stamp" the gib, showing that the
  gib was done by our engine and not by a user.
  """
  @spec mut8(String.t, map, map) :: map
  def mut8(src_ib_gib,
           new_data,
           opts \\ @default_transform_options)
    when is_bitstring(src_ib_gib) and is_map(new_data) do
    ib = "mut8"
    relations = %{
      "dna" => ["ib#{delim}gib", "mut8#{delim}gib"]
    }
    data = %{"src_ib_gib" => src_ib_gib, "new_data" => new_data}
    gib = Helper.hash(ib, relations, data) |> stamp_if_needed(opts[:gib_stamp])
    %{
      ib: ib,
      gib: gib,
      rel8ns: relations,
      data: data
    }
  end

  @doc """
  Creates a rel8 transform that will rel8 the given `src_ib_gib` to the given
  `dest_ib_gib` according to details in given `how` map.

  It is expecting `how` to include at least keys called src_rel8n and dest_rel8n
  which describe `how` the `src_ib_gib` is related to the `dest_ib_gib`.
  `src_rel8n` will add a relation to the src with this name of the rel8n, and
  `dest-rel8n` will add a relation to the dest.
  """
  @spec rel8(String.t, String.t, list(String.t), list(String.t), map) :: map
  def rel8(src_ib_gib,
           dest_ib_gib,
           src_rel8ns \\ @default_rel8ns,
           dest_rel8ns \\ @default_rel8ns,
           opts \\ @default_transform_options)
    when is_bitstring(src_ib_gib) and is_bitstring(dest_ib_gib) and
         src_ib_gib !== dest_ib_gib and
         src_ib_gib !== "ib#{@delim}gib" and
         dest_ib_gib !== "ib#{@delim}gib" and
         is_list(src_rel8ns) and
         is_list(dest_rel8ns) and
         is_map(opts) do

    src_rel8ns =
      if length(src_rel8ns) == 0 do
        @default_rel8ns
      else
        src_rel8ns
      end
    dest_rel8ns =
      if length(dest_rel8ns) == 0 do
        @default_rel8ns
      else
        dest_rel8ns
      end
    ib = "rel8"
    relations = %{
      "dna" => ["ib#{delim}gib", "rel8#{delim}gib"]
    }
    data = %{
      "src_ib_gib" => src_ib_gib,
      "dest_ib_gib" => dest_ib_gib,
      "src_rel8ns" => src_rel8ns |> Enum.concat(@default_rel8ns) |> Enum.uniq,
      "dest_rel8ns" => dest_rel8ns |> Enum.concat(@default_rel8ns) |> Enum.uniq
    }
    gib = Helper.hash(ib, relations, data) |> stamp_if_needed(opts[:gib_stamp])
    %{
      ib: ib,
      gib: gib,
      rel8ns: relations,
      data: data
    }
  end

  @doc """
  Creates a `query` transform ib_gib info map containing the given
  `query_options`.
  """
  def query(query_options)
    when is_map(query_options) do

    ib = "query"

    who = IbGib.QueryOptionsFactory.get_identities(query_options)
    relations =
      if who == nil do
        %{
          "ancestor" => [@root_ib_gib, "query#{@delim}gib"],
          "dna" => [@root_ib_gib],
          "past" => @default_past
        }
      else
        %{
          "ancestor" => [@root_ib_gib, "query#{@delim}gib"],
          "dna" => [@root_ib_gib],
          "past" => @default_past,
          "identity" => who
        }
      end

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

  # Stamping a gib means that it is "official", since a user doesn't (shouldn't)
  # have the ability to create their own gib.
  @spec stamp_if_needed(String.t, boolean) :: String.t
  defp stamp_if_needed(gib, is_needed) when is_boolean(is_needed) do
    if is_needed do
      # I'm both prepending and appending for visual purposes. When querying,
      # I only need to search for: where gib `LIKE` "#{gib_stamp}%"
      gib = Helper.stamp_gib!(gib)
    else
      gib
    end
  end
  defp stamp_if_needed(gib, is_needed) do
    gib
  end

end
