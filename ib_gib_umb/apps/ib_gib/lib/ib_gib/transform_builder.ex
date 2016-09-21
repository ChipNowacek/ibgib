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

  ### Fork

  TransformBuilder.plan(identity_ib_gibs)
  ~>> add_step(%{
        "name" => "fork1",
        "in" => "~[src]", # ~ means string literal "at runtime"
        "f" => %{
          "type" => "fork",
          "dest_ib" => "~[src.ib]"
        }
      })

  ### Instance

  TransformBuilder.plan(identity_ib_gibs)
  ~>> add_step(%{
       "name" => "fork1",
       "in" => "~[src]", # ~ means string literal "at runtime"
       "f" => %{
         "type" => "fork",
         "dest_ib" => "~[src.ib]"
       }
     })
  ~>> add_step(%{
       "name" => "rel8_instance",
       "in" => "[fork1.result]",
       "f" => %{
         "type" => "rel8",
         "other" => [src],
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
      "identity" => identity_ib_gibs
    }
    data = plan
    gib = Helper.hash(ib, relations, data) |> stamp_if_needed(opts[:gib_stamp])
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
                 "arg" => arg,
                 "f" => %{
                   "name" => "fork",
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

  def add_fork(plan, name, arg, dest_ib) do
    add_step(
              plan,
              %{
                "name" => name,
                "arg" => arg,
                "f" => %{
                  "name" => "fork",
                  "dest_ib" => dest_ib
                }
              }
            )
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
