defmodule IbGib.Transform.Plan.Factory do
  @moduledoc """
  Uses the `IbGib.Transform.Plan.Builder` to create plans for transforming
  ibGibs.

  Using `PB` because it's short and used a lot...think PlanBuilder & Jelly!
  """

  # ----------------------------------------------------------------------------
  # alias, import, require, use
  # ----------------------------------------------------------------------------

  require Logger

  import OK, only: :macros

  alias IbGib.Transform.Plan.Builder, as: PB
  # import IbGib.Helper
  use IbGib.Constants, :ib_gib

  # ----------------------------------------------------------------------------
  # Basic Transform Plans
  # ----------------------------------------------------------------------------

  @doc """
  Builds a single-step plan with a simple `fork` transform.

  Returns {:ok, plan} | {:error, reason}
  """
  @spec fork(list(String.t), String.t, map) :: {:ok, map} | {:error, String.t}
  def fork(identity_ib_gibs, dest_ib, opts) do
    {:ok, identity_ib_gibs}
    ~>> PB.plan("[src]", opts)
    ~>> PB.add_fork("fork1", dest_ib)
    ~>> PB.add_plan_name("fork")
    ~>> PB.add_plan_uid()
    ~>> PB.yo()
  end

  @doc """
  Builds a single-step plan with a simple `mut8` transform.

  Returns {:ok, plan} | {:error, reason}
  """
  @spec mut8(list(String.t), map, map) :: {:ok, map} | {:error, String.t}
  def mut8(identity_ib_gibs, new_data, opts) do
    {:ok, identity_ib_gibs}
    ~>> PB.plan("[src]", opts)
    ~>> PB.add_mut8("mut81", new_data)
    ~>> PB.add_plan_name("mut8")
    ~>> PB.add_plan_uid()
    ~>> PB.yo()
  end

  @doc """
  Builds a single-step plan with a simple `rel8` transform.

  Returns {:ok, plan} | {:error, reason}
  """
  @spec rel8(list(String.t), String.t, list(String.t), map) :: {:ok, map} | {:error, String.t}
  def rel8(identity_ib_gibs, other_ib_gib, rel8ns, opts) do
    {:ok, identity_ib_gibs}
    ~>> PB.plan("[src]", opts)
    ~>> PB.add_rel8("rel81", other_ib_gib, rel8ns)
    ~>> PB.add_plan_name("rel8")
    ~>> PB.add_plan_uid()
    ~>> PB.yo()
  end

  # ----------------------------------------------------------------------------
  # Multi-step Transform Plans
  # ----------------------------------------------------------------------------

  @doc """
  Builds a multi-step plan to "instance" an ibGib.

  This will first fork the ibGib, and then add an `instance_of` rel8n to the
  source.
  """
  @spec instance(list(String.t), String.t, map) :: {:ok, map} | {:error, String.t}
  def instance(identity_ib_gibs, dest_ib, opts) do
    {:ok, identity_ib_gibs}
    ~>> PB.plan("[src]", opts)
    ~>> PB.add_fork("fork1", dest_ib)
    ~>> PB.add_rel8("rel8_2_src", "[plan.src]", ["instance_of"])
    ~>> PB.add_plan_name("instance")
    ~>> PB.add_plan_uid()
    ~>> PB.yo()
  end

  @doc """
  Updates a rel8n from an old ib_gib to a new ib_gib.

  This will create a plan that first unrel8s the `old_ib_gib` which should be
  rel8d via `rel8n` to the ibGib that this plan is applied to. Then it will
  rel8 that ibGib to the `new_ib_gib` using the same given `rel8n`.

  ## Use Case

  I'm adding this to be able to update a context ibGib's pointer to a new
  version of the same ibGib. So if Context CTX^1 has a rel8n to A^1, and A^1 is
  mut8d to create A^2, then CTX^1 should update to point to A^2 in place of A^1.
  This update will create CTX^2.

  NB: Version numbers 1 & 2 above are of course are actually gibs which are
  hashes, not an incrementing integer. Using integers for didactic purposes
  only.
  """
  @spec update_rel8n(list(String.t), String.t, String.t, String.t, map) :: {:ok, map} | {:error, String.t}
  def update_rel8n(identity_ib_gibs, rel8n, old_ib_gib, new_ib_gib, opts \\ @default_transform_options) do
    {:ok, identity_ib_gibs}
    ~>> PB.plan("[src]", opts)
    ~>> PB.add_rel8("unrel8_old", old_ib_gib, ["-" <> rel8n])
    ~>> PB.add_rel8("rel8_new", new_ib_gib, [rel8n])
    ~>> PB.add_plan_name("update_rel8n")
    ~>> PB.add_plan_uid()
    ~>> PB.yo()
  end

  # @doc """
  # Builds a multi-step plan to create a new ibGib and "add" it to some other
  # ibGib (`add_target`) via some `rel8ns`.
  #
  # This plan instances the src ibGib with the given `dest_ib`. It then
  # rel8s the new ibGib instance to the `add_target` ibGib with the given
  # `rel8ns`.
  #
  # This should be able to be used for adding pics, comments, and any ol' blank
  # ibGib to an existing ibGib.
  # """
  # @spec add_ibgib(list(String.t), String.t, String.t, list(String.t), map) :: {:ok, map} | {:error, String.t}
  # def add_ibgib(identity_ib_gibs, add_target, dest_ib, data, rel8ns, opts) do
  #   {:ok, identity_ib_gibs}
  #   ~>> PB.plan("[src]", opts)
  #   ~>> PB.add_fork("fork1", dest_ib)
  #   ~>> PB.add_rel8("rel8_2_src", "[plan.src]", ["instance_of"])
  #   ~>> PB.add_rel8("rel8_2_target", add_target, rel8ns)
  #   ~>> PB.yo()
  # end
end
