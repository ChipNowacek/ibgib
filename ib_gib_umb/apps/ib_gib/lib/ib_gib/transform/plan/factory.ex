defmodule IbGib.Transform.Plan.Factory do
  @moduledoc """
  Uses the `IbGib.Transform.Plan.Builder` to create plans for transforming
  ibGibs.
  """

  # ----------------------------------------------------------------------------
  # alias, import, require, use
  # ----------------------------------------------------------------------------

  require Logger

  import OK, only: :macros

  alias IbGib.Transform.Plan.Builder, as: TB

  # ----------------------------------------------------------------------------
  # Basic Transform Plans
  # ----------------------------------------------------------------------------

  def fork(identity_ib_gibs, dest_ib, opts) do
    # {:ok, plan} <- TB.plan(identity_ib_gibs, "[src]", opts),
    # {:ok, plan} <- TB.add_fork(plan, "fork1", dest_ib),
    # {:ok, plan} <- TB.yo(plan),
    {:ok, identity_ib_gibs}
    ~>> TB.plan("[src]", opts)
    ~>> TB.add_fork("fork1", dest_ib)
    ~>> TB.yo
  end

  def mut8(identity_ib_gibs, new_data, opts) do
    # {:ok, plan} <- TB.plan(identity_ib_gibs, "[src]", opts),
    # {:ok, plan} <- TB.add_mut8(plan, "mut81", new_data),
    # {:ok, plan} <- TB.yo(plan),
    {:ok, identity_ib_gibs}
    ~>> TB.plan("[src]", opts)
    ~>> TB.add_mut8("mut81", new_data)
    ~>> TB.yo
  end

  def rel8(identity_ib_gibs, other_ib_gib, rel8ns, opts) do
    # {:ok, plan} <- TB.plan(identity_ib_gibs, "[src]", opts),
    # {:ok, plan} <- TB.add_rel8(plan, "rel81", other_ib_gib, rel8ns),
    # {:ok, plan} <- TB.yo(plan),
    {:ok, identity_ib_gibs}
    ~>> TB.plan("[src]", opts)
    ~>> TB.add_rel8("rel81", other_ib_gib, rel8ns)
    ~>> TB.yo
  end

  # ----------------------------------------------------------------------------
  # Multi-step Transform Plans
  # ----------------------------------------------------------------------------

  def instance(identity_ib_gibs, dest_ib, opts) do
    # {:ok, plan} <- TB.plan(identity_ib_gibs, "[src]", opts),
    # {:ok, plan} <- TB.add_fork(plan, "fork1", dest_ib),
    # {:ok, plan} <- TB.add_rel8(plan, "rel8_2_src", "[plan.src]", ["instance_of"]),
    # {:ok, plan} <- TB.yo(plan),
    {:ok, identity_ib_gibs}
    ~>> TB.plan("[src]", opts)
    ~>> TB.add_fork("fork1", dest_ib)
    ~>> TB.add_rel8("rel8_2_src", "[plan.src]", ["instance_of"])
    ~>> TB.yo
  end
end
