defmodule IbGib.Data.Schemas.BinaryModel do
  @moduledoc """
  This is the primary model that simply persists IbGib in the db.
  """


  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  use Ecto.Schema
  import Ecto.Changeset
  alias IbGib.Data.Schemas.ValidateHelper


  schema "binaries" do
    field :binary_id, :string
    field :binary_data, :binary

    timestamps([usec: true])
  end

  @required_fields ~w(binary_id binary_data)
  @optional_fields ~w()

  def changeset(content, params \\ :empty) do
    content
    |> cast(params, @required_fields, @optional_fields)
    |> validate_required([:binary_id, :binary_data])
    |> validate_length(:binary_id, min: @hash_length, max: @hash_length)
    |> validate_length(:binary_data, min: 1, max: @max_data_size)
    |> unique_constraint(:binary_id, name: :binaries_binary_id_index)
  end
end
