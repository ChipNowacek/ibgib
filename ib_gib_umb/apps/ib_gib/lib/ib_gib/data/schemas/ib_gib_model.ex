defmodule IbGib.Data.Schemas.IbGibModel do
  @moduledoc """
  This is the primary model that simply persists IbGib in the db.
  """
  use IbGib.Constants, :error_msgs

  use Ecto.Schema
  import Ecto.Changeset
  alias IbGib.Data.Schemas.ValidateHelper

  schema "ibgibs" do
    field :ib, :string
    field :gib, :string
    field :data, :map
    field :rel8ns, :map

    timestamps
  end

  @required_fields ~w(ib gib rel8ns)
  @optional_fields ~w(data)
  @min 1
  @max 64

  def changeset(content, params \\ :empty) do
    content
    |> cast(params, @required_fields, @optional_fields)
    |> validate_required([:ib, :gib, :rel8ns])
    |> validate_length(:ib, min: @min, max: @max)
    |> validate_length(:gib, min: @min, max: @max)
    |> validate_change(:rel8ns, &ValidateHelper.do_validate_change(&1,&2))
    |> unique_constraint(:ib, name: :ibgibs_ib_gib_index)
    |> unique_constraint(:gib, name: :ibgibs_ib_gib_index)
  end
end
