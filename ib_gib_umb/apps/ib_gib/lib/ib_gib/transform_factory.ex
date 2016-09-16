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
  use IbGib.Constants, :error_msgs


  defp validate_identity_ib_gibs(identity_ib_gibs)
    when is_list(identity_ib_gibs) do
    valid_identity_ib_gibs =
      length(identity_ib_gibs) > 0 and
      identity_ib_gibs |> Enum.all?(&(Helper.valid_ib_gib?(&1)))
    if valid_identity_ib_gibs do
      {:ok, :ok}
    else
      emsg = emsg_invalid_args(identity_ib_gibs)
      Logger.error emsg
      {:error, emsg}
    end
  end
  defp validate_identity_ib_gibs(identity_ib_gibs) do
    {:error, emsg_invalid_args(identity_ib_gibs)}
  end

  @doc """
  Creates a fork with source `src_ib_gib` and dest_ib of given `dest_ib`. In
  most cases, no `dest_ib` need be specified, so it will just create a new
  random `ib`.

  Returns {:ok, info} | {:error, "reason"}
  """
  @spec fork(String.t, list(String.t), String.t, map) :: {:ok, map} | {:error, String.t}
  def fork(src_ib_gib, # \\ "ib#{@delim}gib",
           identity_ib_gibs,
           dest_ib,
           opts \\ @default_transform_options)
  def fork(src_ib_gib, identity_ib_gibs, dest_ib, opts)
    when is_bitstring(src_ib_gib) and is_list(identity_ib_gibs) and
         is_bitstring(dest_ib) and is_map(opts) do

    case validate_identity_ib_gibs(identity_ib_gibs) do
      {:ok, :ok} ->
        ib = "fork"

        relations = %{
          "ancestor" => @default_ancestor ++ ["fork#{@delim}gib"],
          "past" => @default_past,
          "dna" => @default_dna,
          "identity" => identity_ib_gibs
        }
        data = %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib}
        gib = Helper.hash(ib, relations, data) |> stamp_if_needed(opts[:gib_stamp])
        result = %{
          ib: ib,
          gib: gib,
          rel8ns: relations,
          data: data
        }
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end
  def fork(src_ib_gib, identity_ib_gibs, dest_ib, opts) do
    {:error, emsg_invalid_args([src_ib_gib, identity_ib_gibs, dest_ib, opts])}
  end

  @doc """
  Creates a mut8 transform that will mut8 the internal `data` map of the given
  `src_ib_gib`. This will perform a merge of the given `new_data` map onto the
  existing `data` map, replacing any identical keys.

  If `opts` :gib_stamp is true, then we will "stamp" the gib, showing that the
  gib was done by our engine and not by a user.
  """
  @spec mut8(String.t, list(String.t), map, map) :: {:ok, map} | {:error, String.t}
  def mut8(src_ib_gib,
           identity_ib_gibs,
           new_data,
           opts)
 def mut8(src_ib_gib, identity_ib_gibs, new_data, opts)
    when is_bitstring(src_ib_gib) and is_list(identity_ib_gibs) and
         is_map(new_data) and is_map(opts) do

    case validate_identity_ib_gibs(identity_ib_gibs) do
      {:ok, :ok} ->
        ib = "mut8"
        relations = %{
          "ancestor" => @default_ancestor ++ ["mut8#{@delim}gib"],
          "past" => @default_past,
          "dna" => @default_dna,
          "identity" => identity_ib_gibs
        }
        data = %{"src_ib_gib" => src_ib_gib, "new_data" => new_data}
        gib = Helper.hash(ib, relations, data) |> stamp_if_needed(opts[:gib_stamp])
        result = %{
          ib: ib,
          gib: gib,
          rel8ns: relations,
          data: data
        }
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end
  def mut8(src_ib_gib, identity_ib_gibs, new_data, opts) do
    {:error, emsg_invalid_args([src_ib_gib, identity_ib_gibs, new_data, opts])}
  end

  @doc """
  Creates a rel8 transform that will rel8 the given `src_ib_gib` to the given
  `dest_ib_gib` according to details in given `how` map.

  It is expecting `how` to include at least keys called src_rel8n and dest_rel8n
  which describe `how` the `src_ib_gib` is related to the `dest_ib_gib`.
  `src_rel8n` will add a relation to the src with this name of the rel8n, and
  `dest-rel8n` will add a relation to the dest.
  """
  @spec rel8(String.t, String.t, list(String.t), list(String.t), list(String.t), map) :: map
  def rel8(src_ib_gib,
           dest_ib_gib,
           identity_ib_gibs,
           src_rel8ns,
           dest_rel8ns,
           opts)
    when is_bitstring(src_ib_gib) and is_bitstring(dest_ib_gib) and
         src_ib_gib !== dest_ib_gib and src_ib_gib !== @root_ib_gib and
         dest_ib_gib !== @root_ib_gib and
         is_list(identity_ib_gibs) and length(identity_ib_gibs) >= 1 and
         is_list(src_rel8ns) and is_list(dest_rel8ns) and
         is_map(opts) do

    case validate_identity_ib_gibs(identity_ib_gibs) do
      {:ok, :ok} ->
        src_rel8ns =
          if length(src_rel8ns) == 0, do: @default_rel8ns, else: src_rel8ns
        dest_rel8ns =
          if length(dest_rel8ns) == 0, do: @default_rel8ns, else: dest_rel8ns

        ib = "rel8"
        relations = %{
          "ancestor" => @default_ancestor ++ ["rel8#{@delim}gib"],
          "past" => @default_past,
          "dna" => @default_dna,
          "identity" => identity_ib_gibs
        }
        data = %{
          "src_ib_gib" => src_ib_gib,
          "dest_ib_gib" => dest_ib_gib,
          "src_rel8ns" =>
            src_rel8ns |> Enum.concat(@default_rel8ns) |> Enum.uniq,
          "dest_rel8ns" =>
            dest_rel8ns |> Enum.concat(@default_rel8ns) |> Enum.uniq
        }
        gib =
          Helper.hash(ib, relations, data) |> stamp_if_needed(opts[:gib_stamp])
        result = %{
          ib: ib,
          gib: gib,
          rel8ns: relations,
          data: data
        }
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Creates a `query` transform ib_gib info map containing the given
  `query_options`.
  """
  @spec query(list(String.t), map) :: {:ok, map} | {:error, String.t}
  def query(identity_ib_gibs, query_options)
    when is_list(identity_ib_gibs) and is_map(query_options) do

    case validate_identity_ib_gibs(identity_ib_gibs) do
      {:ok, :ok} ->
        ib = "query"

        relations =
          %{
            "ancestor" => [@root_ib_gib, "query#{@delim}gib"],
            "dna" => [@root_ib_gib],
            "past" => @default_past,
            "identity" => identity_ib_gibs
          }

        data = %{
          "options" => query_options
        }
        gib = Helper.hash(ib, relations, data)
        result = %{
          ib: ib,
          gib: gib,
          rel8ns: relations,
          data: data
        }
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end
  def query(query_opts) do
    {:error, emsg_invalid_args(query_opts)}
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
