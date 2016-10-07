defmodule WebGib.Data.Repo.Migrations.Init do
  @moduledoc """
  Create the primary tables, keys, etc., for the
  `WebGib.Data.Schemas.TokenModel`.
  """

  use Ecto.Migration

  def change do
    create table(:email_login_tokens) do
      add :email_addr, :string
      add :token, :string
      add :ident_pin_hash, :string

      timestamps([usec: true])
    end

    create index(:email_login_tokens,
                 [:email_addr, :ident_pin_hash],
                 name: :email_login_tokens_email_addr_ident_pin_hash_index)
    create unique_index(:email_login_tokens,
                        [:email_addr],
                        name: :email_login_tokens_email_addr_index)
  end
end
