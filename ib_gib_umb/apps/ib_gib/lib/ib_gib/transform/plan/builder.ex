defmodule IbGib.Transform.Plan.Builder do
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
    opts: %{
      "gib_stamp" => "true"
    },
    "i": "1",
    steps: [
      %{
        # name will make this step accessible to proceeding steps via variable
        "name": "some name"

        # Which step in the plan is this? 1, 2, 3, etc.
        "i": "1",

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

  import IbGib.Transform.Plan.Helper
  import IbGib.Helper
  import IbGib.Macros

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs


  @doc """
  Starts a compiler plan builder (info map).
  """
  def plan(identity_ib_gibs, src, opts)
    when is_list(identity_ib_gibs) and length(identity_ib_gibs) >= 1 do
      case validate_identity_ib_gibs(identity_ib_gibs) do
        {:ok, :ok} ->
          plan = %{
            "identities" => identity_ib_gibs,
            "src" => src,
            "i" => "1",
            "steps" => [],
            "opts" => opts
          }
          {:ok, plan}

        {:error, reason} ->
          {:error, reason}
      end
  end

  def yo(plan) do
    ib = "plan"

    relations = %{
      "ancestor" => @default_ancestor ++ ["plan#{@delim}gib"],
      "past" => @default_past,
      "dna" => @default_dna,
      "identity" => plan["identities"]
    }
    data = plan
    gib =
      hash(ib, relations, data)
      |> stamp_if_needed(plan["opts"]["gib_stamp"] == "true")
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

  `arg` is the thing we will transform with "function" created from `f_data`.
  `f_data` is the information to create a "transform function" ib_gib.
  """
  def add_step(plan,
               %{"name" => _name,
                 "f_data" => %{
                   "type" => "fork",
                   "dest_ib" => _dest_ib
                  }
                } = step) do
    step_index = count_steps(plan["steps"]) + 1
    step = Map.put(step, "i", "#{step_index}")
    plan = Map.put(plan, "steps", plan["steps"] ++ [step])
    {:ok, plan}
  end
  def add_step(plan,
               %{"name" => _name,
                 "f_data" => %{
                   "type" => "mut8",
                   "new_data" => _new_data
                  }
                } = step) do
    step_index = count_steps(plan["steps"]) + 1
    step = Map.put(step, "i", "#{step_index}")
    plan = Map.put(plan, "steps", plan["steps"] ++ [step])
    {:ok, plan}
  end
  def add_step(plan,
               %{"name" => _name,
                 "f_data" => %{
                   "type" => "rel8",
                   "other_ib_gib" => _other_ib_gib,
                   "rel8ns" => rel8ns
                  }
                } = step) do

    rel8ns = rel8ns |> Enum.concat(@default_rel8ns) |> Enum.uniq
    step_f_data = Map.put(step["f_data"], "rel8ns", rel8ns)
    step = Map.put(step, "f_data", step_f_data)

    step_index = count_steps(plan["steps"]) + 1
    step = Map.put(step, "i", "#{step_index}")
    plan = Map.put(plan, "steps", plan["steps"] ++ [step])
    {:ok, plan}
  end
  def add_step(plan, step) do
    invalid_args([plan, step])
  end

  def add_fork(plan, name, dest_ib)
    when is_bitstring(dest_ib) do
    add_step(
              plan,
              %{
                "name" => name,
                "f_data" => %{
                  "type" => "fork",
                  "dest_ib" => dest_ib
                }
              }
            )
  end
  def add_fork(plan, name, dest_ib) do
    invalid_args([plan, name, dest_ib])
  end

  def add_mut8(plan, name, new_data)
    when is_map(new_data) do
    add_step(
              plan,
              %{
                "name" => name,
                "f_data" => %{
                  "type" => "mut8",
                  "new_data" => new_data
                }
              }
            )
  end
  def add_mut8(plan, name, new_data) do
    invalid_args([plan, name, new_data])
  end

  def add_rel8(plan, name, other_ib_gib, rel8ns)
    when is_bitstring(other_ib_gib) and other_ib_gib !== @root_ib_gib and
         is_list(rel8ns) do
    add_step(
              plan,
              %{
                "name" => name,
                "f_data" => %{
                  "type" => "rel8",
                  "other_ib_gib" => other_ib_gib,
                  "rel8ns" => rel8ns |> Enum.concat(@default_rel8ns) |> Enum.uniq,
                }
              }
            )
  end
  def add_rel8(plan, name, other_ib_gib, rel8ns) do
    invalid_args([plan, name, other_ib_gib, rel8ns])
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
    _ = Logger.warn "Invalid args: #{inspect [gib, is_needed]}"
    gib
  end

end
