defmodule IbGib.Data.Repo.Migrations.CreateIbgibs do
  @moduledoc """
  Create the primary tables, keys, etc., for the
  `IbGib.Data.Schemas.IbGibModel`.
  """

  use Ecto.Migration

  def change do
    # v2.0.4 has a problem with the comment in the migration.
    # create table(:ibgibs, comment: "Primary table for ibGib data.") do
    create table(:ibgibs) do
      add :ib, :string
      add :gib, :string
      add :data, :map
      add :rel8ns, :map

      timestamps([usec: true])
    end

    create index(:ibgibs, [:ib], name: :ibgibs_ib_index)
    create index(:ibgibs, [:gib], name: :ibgibs_gib_index)
    create unique_index(:ibgibs, [:ib, :gib], name: :ibgibs_ib_gib_index)
  end
end
