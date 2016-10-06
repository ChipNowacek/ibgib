defmodule WebGib.Data.Schemas.TokenModel do
  @moduledoc """
  Used for storing the token for a given user when logging in via email.
  """

  use Ecto.Schema
  import Ecto.Changeset

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :validation
  use WebGib.Constants, :validation


  schema "email_login_tokens" do
    field :email_addr, :string
    field :token, :string
    field :ident_pin_hash, :string

    timestamps([usec: true])
  end

  @required_fields ~w(email_addr token ident_pin_hash)
  @optional_fields ~w()

  def changeset(content, params \\ :empty) do
    content
    |> cast(params, @required_fields, @optional_fields)
    |> validate_required([:email_addr, :token, :ident_pin_hash])
    |> validate_length(:email_addr,
                       min: @min_email_addr_size,
                       max: @max_email_addr_size)
    |> validate_length(:token,
                       min: @hash_length,
                       max: @hash_length)
    |> validate_length(:ident_pin_hash,
                       min: @hash_length,
                       max: @hash_length)
    |> unique_constraint(:email_addr,
                         name: :email_login_tokens_email_addr_index)
  end

end
