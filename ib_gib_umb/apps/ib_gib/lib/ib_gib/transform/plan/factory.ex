defmodule IbGib.Transform.Plan.Factory do
  @moduledoc """
  Uses the `IbGib.Transform.Plan.Builder` to create plans for transforming
  ibGibs.
  """

  # ----------------------------------------------------------------------------
  # alias, import, require, use
  # ----------------------------------------------------------------------------

  require Logger

  import IbGib.Helper
  alias IbGib.Transform.Plan.Builder, as: PB

  # ----------------------------------------------------------------------------
  # Basic Transform Plans
  # ----------------------------------------------------------------------------

  @doc """
  Builds a single-step plan with a simple `fork` transform.

  Returns {:ok, plan} | {:error, reason}
  """
  @spec fork(list(String.t), String.t, map) :: {:ok, map} | {:error, String.t}
  def fork(identity_ib_gibs, dest_ib, opts) do
    with(
      {:ok, plan} <- PB.plan(identity_ib_gibs, "[src]", opts),
      {:ok, plan} <- PB.add_fork(plan, "fork1", dest_ib),
      {:ok, plan} <- PB.yo(plan)
    ) do
      {:ok, plan}
    else
      error -> default_handle_error(error)
    end
  end

  @doc """
  Builds a single-step plan with a simple `mut8` transform.

  Returns {:ok, plan} | {:error, reason}
  """
  @spec mut8(list(String.t), map, map) :: {:ok, map} | {:error, String.t}
  def mut8(identity_ib_gibs, new_data, opts) do
    with(
      {:ok, plan} <- PB.plan(identity_ib_gibs, "[src]", opts),
      {:ok, plan} <- PB.add_mut8(plan, "mut81", new_data),
      {:ok, plan} <- PB.yo(plan)
    ) do
      {:ok, plan}
    else
      error -> default_handle_error(error)
    end
  end

  @doc """
  Builds a single-step plan with a simple `rel8` transform.

  Returns {:ok, plan} | {:error, reason}
  """
  @spec rel8(list(String.t), String.t, list(String.t), map) :: {:ok, map} | {:error, String.t}
  def rel8(identity_ib_gibs, other_ib_gib, rel8ns, opts) do
    with(
      {:ok, plan} <- PB.plan(identity_ib_gibs, "[src]", opts),
      {:ok, plan} <- PB.add_rel8(plan, "rel81", other_ib_gib, rel8ns),
      {:ok, plan} <- PB.yo(plan)
    ) do
      {:ok, plan}
    else
      error -> default_handle_error(error)
    end
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
    with(
      {:ok, plan} <- PB.plan(identity_ib_gibs, "[src]", opts),
      {:ok, plan} <- PB.add_fork(plan, "fork1", dest_ib),
      {:ok, plan} <- PB.add_rel8(plan, "rel8_2_src", "[plan.src]", ["instance_of"]),
      {:ok, plan} <- PB.yo(plan)
    ) do
      {:ok, plan}
    else
      error -> default_handle_error(error)
    end
  end
end
