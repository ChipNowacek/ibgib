defmodule IbGib.TransformBuilder do
  @moduledoc """
  This factory module generates ib_gib transform info maps for the fundamental
  transforms, composite transforms, and queries:
    * fork, mut8, rel8
    * plan, step
    * query

  These functions are used by the `IbGib.Expression` module itself, so ATOW
  (2016/09/20) no other consumers need to use these.

  The state that gets built has the following shape:

  %{
    identities: ["id1^123", "id2^234", etc.]
    mode: "plan"|"transform"|"query",

    steps: []
  }

  TransformBuilder.begin(identity_ib_gibs)
  |> plan
  |> with_step(%{
       "name" => "fork1",
       "src" => "~[src]", # ~ indicates string literal when compile transform
       "tx_data" => %{
         "type" => "fork",
         "dest_ib" => "~[src.ib]"
       }
     })
  |> with_step(%{
       "name" => "rel8_instance",
       "src" => [fork1.result],
       "tx_data" => %{
         "type" => "rel8",
         "other" => [src],
         "rel8ns" => ["instance_of"]
       }
     })
  |> compile_yo

  TransformBuilder.begin(identity_ib_gibs)
  |> transform
  |> with_fork(%{
       "src" => "@[src]",
       "dest_ib" => "@[src.ib]"
     })
  |> compile_yo
  """


  require Logger

  import IbGib.Helper

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  @doc """
  Starts a builder info.
  """
  def begin(identity_ib_gibs)
    when is_list(identity_ib_gibs) and length(identity_ib_gibs) >= 1 do
      case validate_identity_ib_gibs(identity_ib_gibs) do
        {:ok, :ok} ->
          builder = %{ "identities": identity_ib_gibs }
          {:ok, builder}

        {:error, reason} ->
          {:error, reason}
      end
  end

  def plan(builder) do

  end

  @doc """
  `src` is the thing we will "transform". It's our "arg".
  `t` is the "transform" ib^gib.

  I abhor single-letter vars, but I'm effing tired of this. I can't just call
  it transform since I have a function called that. I don't freaking know.
  """
  def with_step(%{"name" => name, "src" => src, "t" => t}) do

  end
  def with_step(%{"name" => name, "src" => src, "t" => t, "result" => result}) do

  end

  def transform(identity_ib_gibs)
    when is_list(identity_ib_gibs) and length(identity_ib_gibs) >= 1 do

  end


  def with_identities()

  end

  @doc """
  """
  def with_data(transform_type, data)
  def with_data(:fork, %{"dest_ib" => dest_ib, "src" => src} = data) do

  end
  def with_data(:fork, %{"src" => src} = data) do

  end
  def with_data(:fork, %{"dest_ib" => dest_ib} = data) do

  end
  def with_data(:fork, data) do
    emsg = emsg_invalid_args([:fork, data])
    Logger.error emsg
    {:error, emsg}
  end
  def with_data(:mut8, %{"src" => src, "new_data" => new_data} = data) do

  end
  def with_data(:mut8, %{"src" => src} = data) do

  end
  def with_data(:rel8,
                %{
                  "src" => src,
                  "other" => other,
                  "rel8ns" => rel8ns
                  } = data) do

  end
  def with_data(:rel8,
                %{
                  "src" => src,
                  "other" => other,
                  } = data) do

  end
  def with_data(:rel8,
                %{
                  "other" => other,
                  "rel8ns" => rel8ns
                  } = data) do

  end
  def with_data(transform_type, data) do
    emsg = emsg_invalid_args([transform_type, data])
    Logger.error emsg
    {:error, emsg}
  end

  @doc """
  Right now, I'm just wrapping the given `var_name` with square brackets.
  I might change this, so I'm putting it in its own function.
  """
  def get_var_string(var_name) do
    "[#{var_name}]"
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
  `other_ib_gib`.
  """
  @spec rel8(String.t, String.t, list(String.t), list(String.t), map) :: {:ok, map} | {:error, String.t}
  def rel8(src_ib_gib, other_ib_gib, identity_ib_gibs, rel8ns, opts)
    when is_bitstring(src_ib_gib) and is_bitstring(other_ib_gib) and
         src_ib_gib !== other_ib_gib and src_ib_gib !== @root_ib_gib and
         other_ib_gib !== @root_ib_gib and
         is_list(identity_ib_gibs) and length(identity_ib_gibs) >= 1 and
         is_list(rel8ns) and
         is_map(opts) do

    case validate_identity_ib_gibs(identity_ib_gibs) do
      {:ok, :ok} ->
        rel8ns =
          if length(rel8ns) == 0, do: @default_rel8ns, else: rel8ns

        ib = "rel8"
        relations = %{
          "ancestor" => @default_ancestor ++ ["rel8#{@delim}gib"],
          "past" => @default_past,
          "dna" => @default_dna,
          "identity" => identity_ib_gibs
        }
        data = %{
          "src_ib_gib" => src_ib_gib,
          "other_ib_gib" => other_ib_gib,
          "rel8ns" => rel8ns |> Enum.concat(@default_rel8ns) |> Enum.uniq,
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
  def rel8(src_ib_gib, other_ib_gib, identity_ib_gibs, rel8ns, opts) do
    {
      :error,
      emsg_invalid_args([src_ib_gib, other_ib_gib, identity_ib_gibs,
                         rel8ns, opts])
    }
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
