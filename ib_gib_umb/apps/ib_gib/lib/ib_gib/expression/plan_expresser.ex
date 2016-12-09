defmodule IbGib.Expression.PlanExpresser do
  @moduledoc """
  Contains the functions pertaining to an `IbGib.Expression` expressing a plan.

  I'm refactoring this code here to logically organize it. These are not really
  "public" functions though.
  """

  import Enum
  require Logger

  alias IbGib.{Auth.Authz, Expression, Helper}
  alias IbGib.Expression.Apply
  alias IbGib.Transform.Factory, as: TransformFactory
  alias IbGib.Transform.Mut8.Factory, as: Mut8Factory
  alias IbGib.Transform.Plan.Helper, as: PlanHelper
  alias IbGib.Transform.Plan.Factory, as: PlanFactory

  import IbGib.Macros
  # import IbGib.Expression
  import IbGib.Expression.ExpressionHelper

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  def express_plan(identity_ib_gibs, a_ib_gib, a_info, b_ib_gib, _state) do
    _ = Logger.debug "express_impl reached"

    with(
      # -----------------------
      # Get plan process and info
      {:ok, b} <- get_process(identity_ib_gibs, b_ib_gib),
      {:ok, plan_info} <- b |> Expression.get_info,

      # -----------------------
      # Compile the plan to a concrete plan, and get the next step (transform)
      {:ok, {concrete_plan_info, next_step_transform_info, _next_step_index}} <-
        compile(identity_ib_gibs, a_ib_gib, b_ib_gib, plan_info),

      # -----------------------
      # Prepare `a` information.
      {:ok, a_info} <-
        (
          if is_nil(a_info) do
            case get_process(identity_ib_gibs, a_ib_gib) do
              {:ok, a} -> a |> Expression.get_info
              {:error, error} -> {:error, error}
              error -> {:error, inspect error}
            end
          else
            {:ok, a_info}
          end
        ),

      # -----------------------
      # We now have both `a` and `b`.
      # We can now express this "blank" process by applying the next step
      # transform to `a`.
      # This is is where we apply_fork, apply_rel8, apply_mut8.
      # This is an express iteration.
      {:ok, concrete_plan_ib_gib} <- Helper.get_ib_gib(concrete_plan_info),
      {:ok, a_info_with_new_dna} <-
        {:ok, add_rel8n(a_info, "dna", concrete_plan_ib_gib)},
      {:ok, {this_ib_gib, _this_ib, _this_gib, this_info}} <-
        apply_next(a_info_with_new_dna, next_step_transform_info),
      # -----------------------
      # Save this info
      # (This may be premature, since I haven't done anything with dna, and
      #  also there will be a new "final" plan with additional information that
      #  will not be rel8d to this)
      {:ok, :ok} <- IbGib.Data.save(this_info),
      :ok <- IbGib.Expression.Registry.register(this_ib_gib, self()),
      # -----------------------
      {:ok, {final_ib_gib, final_state}} <-
        on_complete_express_iteration(identity_ib_gibs,
                                      this_ib_gib,
                                      this_info,
                                      concrete_plan_info)
    ) do
      # log_yo(:debug, "6\nfinal_ib_gib: #{final_ib_gib}\nfinal_state:\n#{inspect final_state, pretty: true}")
      {:ok, {final_ib_gib, final_state}}
    else
      {:error, reason} ->
        _ = Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        _ = Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  # At this point the "next" step is the one we've just executed.
  # If there are further steps to do, then we must do a few things:
  # * Set the "out" of this step to the ib_gib we've just created.
  # * Save the new plan.
  # * Call express recursively on the plan to get the final ib_gib result.

  # If there are no further steps, then we are done and we can just
  # return this_ib_gib.
  defp on_complete_express_iteration(identity_ib_gibs, this_ib_gib, this_info, plan_info) do
    # regardless of if there are further steps, our state is now set to
    # what we have done so far.
    new_state = %{:info => this_info}

    if plan_complete?(plan_info) do
      {:ok, {this_ib_gib, new_state}}
    else
      with(
        # At this point the "next" step is the one we've just executed.
        {:ok, {next_step, next_step_index}} <- get_next_step(plan_info),
        new_next_step <- Map.put(next_step, "out", this_ib_gib),
        # {:ok, :ok} <-
        new_steps <-
          List.replace_at(plan_info[:data]["steps"],
                          next_step_index - 1,
                          new_next_step),
        new_plan_info_data <- Map.put(plan_info[:data], "steps", new_steps),
        new_plan_info <- Map.put(plan_info, :data, new_plan_info_data),

        # Increment plan "i" (step index)
        new_plan_info <- increment_plan_step_index(new_plan_info),

        # Recalculate the gib hash and save
        new_plan_gib <-
          Helper.hash(new_plan_info[:ib],
                      new_plan_info[:rel8ns],
                      new_plan_info[:data]),
        new_plan_info <- Map.put(new_plan_info, :gib, new_plan_gib),
        # {:ok, :ok} <-
        {:ok, :ok} <- IbGib.Data.save(new_plan_info),

        {:ok, new_plan_ib_gib} <- Helper.get_ib_gib(new_plan_info),

        # Call express recursively with our new information!
        {:ok, final_ib_gib} <-
          Expression.express(identity_ib_gibs, this_ib_gib, this_info, new_plan_ib_gib)
      ) do
        {:ok, {final_ib_gib, new_state}}
      else
        {:error, reason} ->
          _ = Logger.error "#{inspect reason}"
          {:error, reason}
        error ->
          _ = Logger.error "#{inspect error}"
          {:error, "#{inspect error}"}
      end
    end
  end

  defp plan_complete?(plan_info) do
    _ = Logger.debug "plan_info:\n#{inspect plan_info, pretty: true}"
    next_step_index = String.to_integer(plan_info[:data]["i"])
    step_count = PlanHelper.count_steps(plan_info[:data]["steps"])
    _ = Logger.debug "next_step_index: #{next_step_index}\nstep_count: #{step_count}"
    # 1-based index
    cond do
      next_step_index < step_count -> false
      next_step_index = step_count -> true
      true -> raise "Invalid next_step_index: #{next_step_index}\nstep_count: #{step_count}\nThe index should be less than or equal to the step count."
    end
  end

  defp apply_next(a_info, next_info) do
    _ = Logger.debug "next_info:\n#{inspect next_info, pretty: true}"
    with(
      {:ok, {this_ib, this_gib, this_info}} <-
        apply_next_impl(a_info, next_info),
      {:ok, this_ib_gib} <- Helper.get_ib_gib(this_ib, this_gib)
    ) do
      {:ok, {this_ib_gib, this_ib, this_gib, this_info}}
    else
      {:error, reason} ->
        _ = Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        _ = Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  defp apply_next_impl(a_info, %{:ib => "fork"} = next_info) do
    _ = Logger.debug "next_info:\n#{inspect next_info, pretty: true}"
    Apply.apply_fork(a_info, next_info)
  end
  defp apply_next_impl(a_info, %{:ib => "mut8"} = next_info) do
    Apply.apply_mut8(a_info, next_info)
  end
  defp apply_next_impl(a_info, %{:ib => "rel8"} = next_info) do
    Apply.apply_rel8(a_info, next_info)
  end

  # For now, the implementation is just to call start_expression
  defp get_process(_identity_ib_gibs, ib_gib) do
    _ = Logger.debug "ib_gib: #{ib_gib}"
    IbGib.Expression.Supervisor.start_expression(ib_gib)
  end

  defp compile(identity_ib_gibs,
               a_ib_gib,
               b_ib_gib,
               b_info = %{:ib => "plan", :data => %{"src" => src}})
    when is_list(identity_ib_gibs) and
         is_bitstring(a_ib_gib) and
         is_bitstring(b_ib_gib) do

    b_info =
      if src == "[src]" do
        b_info_data = Map.put(b_info[:data], "src", a_ib_gib)
        Map.put(b_info, :data, b_info_data)
      else
        b_info
      end

    _ = Logger.debug "b_info: #{inspect b_info}"
    # _ = Logger.warn "before compile"
    case concretize_and_save_plan(identity_ib_gibs, a_ib_gib, b_ib_gib, b_info) do
      # We have concretized the plan, including the next step transform,
      # and we want to return that new transform to express.
      {:ok, {concrete_plan_info,
             _concrete_plan_ib_gib,
             next_step_transform_info,
             next_step_index}} ->
        # _ = Logger.debug "concrete_plan_ib_gib:\n#{concrete_plan_ib_gib}\nconcrete_plan_info: #{inspect concrete_plan_info, pretty: true}"
        # _ = Logger.warn "after compile"
        {:ok, {concrete_plan_info, next_step_transform_info, next_step_index}}

      # Something went awry.
      {:error, reason} -> {:error, reason}
      error -> {:error, inspect error}
    end
  end

  # Warning, this is a big honking monster. Once it's working, we can try to
  # refactor it to be more elegantly structured, perhaps taking this whole
  # compilation process into its own module, yada yada yada.
  defp concretize_and_save_plan(identity_ib_gibs, a_ib_gib, old_plan_ib_gib, old_plan_info) do
    # _ = Logger.debug "args:\n#{inspect [identity_ib_gibs, a_ib_gib, old_plan_info], [pretty: true]}"

    with(
      # Update our available variables
      available_vars <- get_available_vars(a_ib_gib, old_plan_info),

      # Update our plan with those variables replaced.
      new_plan_info <- replace_variables(available_vars, old_plan_info),

      # With the variables replaced, we now have a possibly more concrete
      # b_info, but it may not be fully concrete.
      {:ok, {next_step, next_step_index}} <- get_next_step(new_plan_info),

      # So right now, we have a "next step" that should be concrete, but we have
      # not yet created its corresponding primitive transform ib_gib, and it
      # has no "ibgib" field. So we need to create
      # the next primitive transform based on the step's f_data, and then
      # fill in the step's "ibgib" field with that ib^gib, e.g. "fork^ABC1234".
      {:ok, next_f_data} <- {:ok, next_step["f_data"]},
      {:ok, {next_step_ibgib, next_step_transform_info}} <-
        build_and_save_next_transform(next_f_data["type"],
                                      identity_ib_gibs,
                                      a_ib_gib,
                                      next_f_data,
                                      new_plan_info),

      # Fill in the next_step's "ibgib" field
      # {:ok, :ok} <- log_yo(:debug, "before...next_step[ibgib]: #{next_step["ibgib"]}"),
      # {:ok, :ok} <- log_yo(:debug, "next_step_transform_info:\n#{inspect next_step_transform_info, pretty: true}"),
      {:ok, next_step} <- {:ok, Map.put(next_step, "ibgib", next_step_ibgib)},
      # {:ok, :ok} <- log_yo(:debug, "after...next_step[ibgib]: #{next_step["ibgib"]}"),

      # Replace the newly edited step in the map
      new_plan_steps <-
        new_plan_info[:data]["steps"] |> convert_to_list_if_needed,
      new_plan_steps <-
        List.replace_at(new_plan_steps, next_step_index - 1, next_step),
      # :ok <- (
      #   if PlanHelper.count_steps(new_plan_info[:data]["steps"]) == 1, do: :ok, else: :error
      # ), #debugg
      new_plan_data <- Map.put(new_plan_info[:data], "steps", new_plan_steps),
      new_plan_info <- Map.put(new_plan_info, :data, new_plan_data),

      # We need to add the previous plan to the past rel8n.
      new_plan_rel8ns_past <-
        new_plan_info[:rel8ns]["past"] ++ [old_plan_ib_gib],
      new_plan_rel8ns <-
        Map.put(new_plan_info[:rel8ns], "past", new_plan_rel8ns_past),
      new_plan_info <-
        Map.put(new_plan_info, :rel8ns, new_plan_rel8ns),

      # At this point, our plan itself is concrete for this iteration, and we
      # need to recalculate the gib hash, and then save it.
      new_plan_gib <-
        Helper.hash(new_plan_info[:ib], new_plan_rel8ns, new_plan_data),
      new_plan_info <- Map.put(new_plan_info, :gib, new_plan_gib),
      # {:ok, :ok} <- log_yo(:debug, "new_plan_info before saving:\n#{inspect new_plan_info, pretty: true}"),

      {:ok, :ok} <- IbGib.Data.save(new_plan_info),
      # {:ok, :ok} <- log_yo(:debug, "saved yaaaaaaaay"),
      {:ok, new_plan_ib_gib} <-
        Helper.get_ib_gib(new_plan_info[:ib], new_plan_gib)
    ) do
      # Whew! ':-O
      # Really need to refactor this.
      {:ok, {new_plan_info, new_plan_ib_gib, next_step_transform_info, next_step_index}}
    else
      {:error, reason} ->
        _ = Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        _ = Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  defp increment_plan_step_index(new_plan_info) do
    _ = Logger.debug "new_plan_info:\n#{inspect new_plan_info, pretty: true}"
    data = new_plan_info[:data]
    steps_count = PlanHelper.count_steps(data["steps"])
    current_i = String.to_integer(data["i"])
    if current_i < steps_count do
      _ = Logger.debug "bumping i. current_i: #{current_i}. steps_count: #{steps_count}"
      data = Map.put(data, "i", "#{current_i + 1}")
      # Return plan with bumped i
      Map.put(new_plan_info, :data, data)
    else
      _ = Logger.debug "i unchanged. current_i: #{current_i}. steps_count: #{steps_count}"
      # Just return plan unchanged
      new_plan_info
    end
  end

  # I don't know if it's the map encoder or something in elixir, but it likes
  # to convert a single-item array/list to just the item and forget the list
  # part of it. Very strange. :-/
  defp convert_to_list_if_needed(item) when is_bitstring(item), do: [item]
  defp convert_to_list_if_needed(item) when is_list(item), do: item
  defp convert_to_list_if_needed(item), do: [item]

  defp build_and_save_next_transform("fork", identity_ib_gibs, src_ib_gib,
    f_data, plan_info) do

    _ = Logger.debug "fork\nplan_info: #{inspect plan_info, pretty: true}"
    # Probably need to actually get this from somewhere, but for now I'm
    # going with the default until I see the reason otherwise.
    # opts = @default_transform_options

    with(
      opts <- plan_info[:data]["opts"],

    # 1. Create transform
      {:ok, fork_info} <-
        TransformFactory.fork(src_ib_gib,
                              identity_ib_gibs,
                              f_data["dest_ib"],
                              opts),
      # 2. Save transform
      {:ok, :ok} <- IbGib.Data.save(fork_info),
      # 3. Get the transform's ib^gib
      {:ok, fork_ib_gib} <- Helper.get_ib_gib(fork_info[:ib], fork_info[:gib])
    ) do
      {:ok, {fork_ib_gib, fork_info}}
    else
      {:error, reason} ->
        _ = Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        _ = Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end
  defp build_and_save_next_transform("mut8", identity_ib_gibs, src_ib_gib,
    f_data, plan_info) do

    # Probably need to actually get this from somewhere, but for now I'm
    # going with the default until I see the reason otherwise.
    # opts = @default_transform_options

    with(
      opts <- plan_info[:data]["opts"],

    # 1. Create transform
      {:ok, mut8_info} <-
        TransformFactory.mut8(src_ib_gib,
                              identity_ib_gibs,
                              f_data["new_data"],
                              opts),
      # 2. Save transform
      {:ok, :ok} <- IbGib.Data.save(mut8_info),
      # 3. Get the transform's ib^gib
      {:ok, mut8_ib_gib} <- Helper.get_ib_gib(mut8_info[:ib], mut8_info[:gib])
    ) do
      {:ok, {mut8_ib_gib, mut8_info}}
    else
      {:error, reason} ->
        _ = Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        _ = Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end
  defp build_and_save_next_transform("rel8", identity_ib_gibs, src_ib_gib,
    f_data, plan_info) do

    # Probably need to actually get this from somewhere, but for now I'm
    # going with the default until I see the reason otherwise.
    # opts = @default_transform_options

    with(
      opts <- plan_info[:data]["opts"],

    # 1. Create transform
      {:ok, rel8_info} <-
        TransformFactory.rel8(src_ib_gib,
                              f_data["other_ib_gib"],
                              identity_ib_gibs,
                              f_data["rel8ns"],
                              opts),
      # 2. Save transform
      {:ok, :ok} <- IbGib.Data.save(rel8_info),
      # 3. Get the transform's ib^gib
      {:ok, rel8_ib_gib} <- Helper.get_ib_gib(rel8_info[:ib], rel8_info[:gib])
    ) do
      {:ok, {rel8_ib_gib, rel8_info}}
    else
      {:error, reason} ->
        _ = Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        _ = Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  defp get_next_step(b_info) do
    # At this point, should always be a next step, i.e. plan isn't complete
    _ = Logger.debug "b_info:\n#{inspect b_info, pretty: true}"
    next_step_index = String.to_integer(b_info[:data]["i"])
    steps = b_info[:data]["steps"]

    # _ = Logger.debug "steps:\n#{inspect steps, pretty: true}"
    # Compensate for the very strange behavior of elixir converting single-item
    # arrays to non-arrays in maps.
    steps = if is_list(steps), do: steps, else: [steps]

    _ = Logger.debug "steps:\n#{inspect steps, pretty: true}\nnext_step_index: #{next_step_index}"

    # next_step_index is 1-based, Enum.at is 0-based
    next_step = Enum.at(steps, next_step_index - 1)
    if next_step do
      _ = Logger.debug "next_step: #{inspect next_step, pretty: true}"
      {:ok, {next_step, next_step_index}}
    else
      {:error, "Next step not found"}
    end
  end

  @doc """
  Given the `available_vars` in the form of `%{"var_name" => "var_value"}`,
  this iterates over all entries in the given `map`, including maps nested
  in values, replacing any value that is a `var_name` and replacing it
  with `var_value`.
  """
  def replace_variables(available_vars, map) when is_map(map) do
    proc_id = RandomGib.Get.some_letters(4)
    Logger.metadata(x: proc_id)
    # _ = Logger.debug "available_vars:\n#{inspect available_vars, pretty: true}\n"
    _ = Logger.debug "map before:\n#{inspect map, pretty: true}"
    result =
      for {key, val} <- map, into: %{} do
        val = replace_variables(available_vars, val)

        # If the Map.get is successful, then replace the variable with it.
        # If it isn't found, then default to the existing value.
        {key, Map.get(available_vars, val, val)}
      end

    Logger.metadata(x: proc_id)
    _ = Logger.debug "map after:\n#{inspect result, pretty: true}"
    result
  end
  def replace_variables(_available_vars, list) when is_list(list) and length(list) == 0 do
    _ = Logger.debug "empty list"
    list
  end
  def replace_variables(available_vars, list) when is_list(list) do
    proc_id = RandomGib.Get.some_letters(4)
    Logger.metadata(x: proc_id)
    _ = Logger.debug "list before:\n#{inspect list, pretty: true}"
    result =
      Enum.map(list, fn(item) -> replace_variables(available_vars, item) end)

    Logger.metadata(x: proc_id)
    _ = Logger.debug "list after:\n#{inspect list, pretty: true}"
    result
  end
  def replace_variables(available_vars, str) when is_bitstring(str) do
    available_vars |> Map.get(str, str)
  end

  def get_available_vars(a_ib_gib, b_info) do
    _ = Logger.debug "args: #{inspect [a_ib_gib, b_info], [pretty: true]}"

    {:ok, {a_ib, _}} = Helper.separate_ib_gib(a_ib_gib)
    plan_src = b_info[:data]["src"]
    {:ok, {plan_src_ib, _}} = Helper.separate_ib_gib(plan_src)

    # Initialize plan variables
    vars = %{
      # The "current" src for this step in the plan
      "[src]" => a_ib_gib,
      "[src.ib]" => a_ib,

      # The original src for the transform plan
      "[plan.src]" => plan_src,
      "[plan.src.ib]" => plan_src_ib
    }

    # Add variables available from previously completed steps and return
    steps = b_info[:data]["steps"]
    steps =
      if is_list(steps) do
        steps
      else
        [steps]
      end
    _ = Logger.debug "steps:\n#{inspect steps, [pretty: true]}"

    completed_steps =
      steps
      |> Enum.filter(fn(step) ->
           output = step["out"]
           output != nil and output != ""
         end)
    _ = Logger.debug "completed_steps:\n#{inspect completed_steps, [pretty: true]}"

    vars =
      if completed_steps != nil and Enum.count(completed_steps) > 0 do
        # Add vars from completed steps
        completed_steps
        |> Enum.reduce(vars, fn(step, acc) ->
             name = step["name"]
             acc
             |> Map.put("[#{name}.ibgib]", step["ibgib"])
             |> Map.put("[#{name}.arg]", step["arg"])
             |> Map.put("[#{name}.out]", step["out"])
           end)
      else
        vars
      end
    _ = Logger.debug "vars:\n#{inspect vars, pretty: true}"
    vars
  end
end
