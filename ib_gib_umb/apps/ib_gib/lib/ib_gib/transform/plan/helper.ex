defmodule IbGib.Transform.Plan.Helper do
  @moduledoc """
  Functions related to transform plans.
  """

  # ----------------------------------------------------------------------------
  # alias, import, require, use
  # ----------------------------------------------------------------------------

  require Logger

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  # ----------------------------------------------------------------------------
  # Functions
  # ----------------------------------------------------------------------------

  @doc """
  Counts the number of step infos in the given steps list.

  ## Examples
  (The counting only relies on the "i" entry in the map, so other data is not
  provided here.)

      iex> steps = [%{"i" => "1"}]
      ...> IbGib.Transform.Plan.Helper.count_steps(steps)
      1

      iex> steps = [%{"i" => "1"}, %{"i" => "2"}]
      ...> IbGib.Transform.Plan.Helper.count_steps(steps)
      2
  """
  def count_steps(steps)
  def count_steps(steps) when is_nil(steps) do
    0
  end
  def count_steps(steps) when is_map(steps) do
    # 1-item lists get morphed into the item for some reason in elixir. :-/
    count_steps([steps])
  end
  def count_steps(steps) when is_list(steps) and length(steps) == 0 do
    0
  end
  def count_steps(steps) when is_list(steps) do
    steps
    |> Enum.reduce(0, fn(step, acc) ->
          i = String.to_integer(step["i"])
          if i > acc, do: i, else: acc
       end)
  end
  def count_steps(steps) do
    emsg = emsg_invalid_args(steps)
    _ = Logger.error emsg
    raise(emsg)
  end

end
