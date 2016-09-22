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
    vars: []
    dnas: []


    steps: [
      %{
        # name will make this step accessible to proceeding steps via variable
        name: "some name"

        # Before compile...
        "ibgib": ""
        # After compile...
        "ibgib": "fork^ABC1234"

        # The input ib^gib resolved at "runtime"
        # ** This should always be set to "[src]" **
        "arg": "[src]",

        # The "function" transform that will act upon the arg
        "f_data": %{
          "type" => "fork",
          "other" => "[plan.src]"
        },

        # If there is no "output" created yet, will not have this key
        # i.e. step["out"] will be nil
        "out": "some ib^gib123", # If output, it will be a single ib^gib
      }
    ]
  }

  Each step looks like this:

  ## Examples

  ### Plain Fork (duplicates existing behavior)

  TransformBuilder.plan(identity_ib_gibs)
  ~>> add_step(%{
        "name" => "fork1",
        "f_data" => %{
          "type" => "fork",
          "dest_ib" => "[src.ib]"
        }
      })

  ### Instance

  TransformBuilder.plan(identity_ib_gibs)
  ~>> add_step(%{
       "name" => "fork1",
       "f_data" => %{
         "type" => "fork",
         "dest_ib" => "[plan.src.ib]"
       }
     })
  ~>> add_step(%{
       "name" => "rel8_instance",
       "f_data" => %{
         "type" => "rel8",
         "other" => "[plan.src]",
         "rel8ns" => ["instance_of"]
       }
     })
  """


  require Logger

  import IbGib.Helper

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs


  @doc """
  Starts a compiler plan builder (info map).
  """
  def plan(identity_ib_gibs, src)
    when is_list(identity_ib_gibs) and length(identity_ib_gibs) >= 1 do
      case validate_identity_ib_gibs(identity_ib_gibs) do
        {:ok, :ok} ->
          plan = %{
            "identities" => identity_ib_gibs,
            "src" => src,
            "steps" => []
          }
          {:ok, plan}

        {:error, reason} ->
          {:error, reason}
      end
  end

  def yo(plan, opts \\ @default_transform_options) do
    ib = "plan"

    relations = %{
      "ancestor" => @default_ancestor ++ ["plan#{@delim}gib"],
      "past" => @default_past,
      "dna" => @default_dna,
      "identity" => plan["identities"]
    }
    data = plan
    gib = hash(ib, relations, data) |> stamp_if_needed(opts[:gib_stamp])
    result = %{
      ib: ib,
      gib: gib,
      rel8ns: relations,
      data: data
    }
    {:ok, result}
  end

  @doc """
  Each step is in the form of:
    arg -> f -> out

  `arg` is the thing we will transform with "function" `f`.
  `f` is the "transform function" ib^gib.
  """
  def add_step(plan,
               %{"name" => name,
                 "arg" => "[src]",
                 "f" => %{
                   "type" => "fork",
                   "dest_ib" => dest_ib
                  } = f
                } = step) do
    plan = Map.put(plan, "steps", plan["steps"] ++ step)
    {:ok, plan}
  end
  def add_step(plan, step) do
    emsg = emsg_invalid_args([plan, step])
    Logger.error emsg
    {:error, emsg}
  end

  def add_fork(plan, name, dest_ib) do
    add_step(
              plan,
              %{
                "name" => name,
                "arg" => "[src]",
                "f" => %{
                  "type" => "fork",
                  "dest_ib" => dest_ib
                }
              }
            )
  end

  # NOT DRY>>>>NOOOOOOOOOOO
  # THIS IS DUPLICATED IN TRANSFORM_FACTORY/BUILDER
  # Stamping a gib means that it is "official", since a user doesn't (shouldn't)
  # have the ability to create their own gib.
  @spec stamp_if_needed(String.t, boolean) :: String.t
  defp stamp_if_needed(gib, is_needed) when is_boolean(is_needed) do
    if is_needed do
      # I'm both prepending and appending for visual purposes. When querying,
      # I only need to search for: where gib `LIKE` "#{gib_stamp}%"
      gib = stamp_gib!(gib)
    else
      gib
    end
  end
  defp stamp_if_needed(gib, is_needed) do
    gib
  end

  # @doc """
  # """
  # def with_data(transform_type, data)
  # def with_data(:fork, %{"dest_ib" => dest_ib, "src" => src} = data) do
  #
  # end
  # def with_data(:fork, %{"src" => src} = data) do
  #
  # end
  # def with_data(:fork, %{"dest_ib" => dest_ib} = data) do
  #
  # end
  # def with_data(:fork, data) do
  #   emsg = emsg_invalid_args([:fork, data])
  #   Logger.error emsg
  #   {:error, emsg}
  # end
  # def with_data(:mut8, %{"src" => src, "new_data" => new_data} = data) do
  #
  # end
  # def with_data(:mut8, %{"src" => src} = data) do
  #
  # end
  # def with_data(:rel8,
  #               %{
  #                 "src" => src,
  #                 "other" => other,
  #                 "rel8ns" => rel8ns
  #                 } = data) do
  #
  # end
  # def with_data(:rel8,
  #               %{
  #                 "src" => src,
  #                 "other" => other,
  #                 } = data) do
  #
  # end
  # def with_data(:rel8,
  #               %{
  #                 "other" => other,
  #                 "rel8ns" => rel8ns
  #                 } = data) do
  #
  # end
  # def with_data(transform_type, data) do
  #   emsg = emsg_invalid_args([transform_type, data])
  #   Logger.error emsg
  #   {:error, emsg}
  # end
  #
  # @doc """
  # Right now, I'm just wrapping the given `var_name` with square brackets.
  # I might change this, so I'm putting it in its own function.
  # """
  # def get_var_string(var_name) do
  #   "[#{var_name}]"
  # end

end
