defmodule IbGib.Data.Repo.Migrations.AddBinaryStorage do
  @moduledoc """
  Create the table holding binary data, e.g. images, as well as a
  unique index on the `binary_id` field.

  The `id` field remains the Postgres auto-generated integer field.

  The ibgibs table's `data` field for those ib_gib with binary data will
  contain "pointers" to the `binary_id` field. But that is nested inside
  of a jsonb construct, and there is no explicit one-to-many relationship
  defined.
  """

  use Ecto.Migration

  def change do
    create table(:binaries) do
      add :binary_id, :string
      add :binary_data, :binary

      timestamps([usec: true])
    end

    create unique_index(:binaries,
                        [:binary_id],
                        name: :binaries_binary_id_index)
  end
end
