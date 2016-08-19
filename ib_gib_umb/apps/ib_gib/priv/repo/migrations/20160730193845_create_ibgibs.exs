defmodule IbGib.Data.Repo.Migrations.CreateIbgibs do
  use Ecto.Migration

  def change do
    create table(:ibgibs, comment: "Primary table for ibGib data.") do
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
