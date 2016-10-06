defmodule WebGib.Data do
  @moduledoc """
  Facade to working with WebGib Data (Repo).

  My original use case for this is storing tokens when logging in via email.
  """

  require Logger
  import Ecto.Query

  alias WebGib.Data.Repo
  alias WebGib.Data.Schemas.TokenModel

  @doc """
  Saves to storage the given `email_addr`, `token`, and `ident_pin_hash` for
  use in the identity email login workflow.

  Returns {:ok, :ok} or {:error, reason}
  """
  @spec save_ident_email_info(String.t, String.t, String.t) :: {:ok, :ok} | {:error, String.t}
  def save_ident_email_info(email_addr, token, ident_pin_hash) do
    _ = Logger.debug "inserting into repo. email_addr: #{email_addr}"

    with(
      # Need to do an upsert on the email_addr being unique. Upsert however is
      # only available in ecto 2.1.0-rc.1 currently. So doing it manually.
      {:ok, :ok} <- delete_if_exists(email_addr),
      {:ok, :ok} <- insert_into_repo(email_addr, token, ident_pin_hash)
    ) do
      {:ok, :ok}
    else
      {:error, reason} when is_bitstring(reason) -> {:error, reason}
      {:error, reason} -> {:error, inspect reason}
      error -> {:error, inspect error}
    end

  end

  defp delete_if_exists(email_addr) do
    _ = Logger.debug "deleting if exists...email_addr: #{email_addr}"
    existing_result =
      TokenModel
      |> where(email_addr: ^email_addr)
      |> select([:id])
      |> Repo.all

    _ = Logger.debug "existing_result:\n#{inspect existing_result}"
    case Enum.count(existing_result) do
      # Delete not needed
      0 -> {:ok, :ok}

      # Delete existing one
      1 ->
        existing = Enum.at(existing_result, 0)
        case Repo.delete(existing) do
          {:ok, _struct} -> {:ok, :ok}

          {:error, _changeset} ->
            emsg = "Error deleting email address #{email_addr}"
            _ = Logger.error emsg
            {:error, emsg}
        end

      # Oops
      _ ->
        emsg = "Error deleting email address #{email_addr}"
        _ = Logger.error emsg
        {:error, emsg}
    end
  end

  defp insert_into_repo(email_addr, token, ident_pin_hash) do
    insert_result =
      %TokenModel{}
      |> TokenModel.changeset(%{
           email_addr: email_addr,
           token: token,
           ident_pin: ident_pin_hash
         })
      |> Repo.insert

    case insert_result do
      {:ok, _model} ->
        _ = Logger.debug "Inserted token for email_addr: #{email_addr}"
        {:ok, :ok}

      {:error, _changeset} ->
        emsg = "Error inserting token with email address #{email_addr}"
        _ = Logger.error emsg
        {:error, emsg}
    end
  end

  @doc """
  Retrieves from storage the ident_email token corresponding to the given
  `email_addr` and `ident_pin_hash`, then deletes this from the repo.

  Returns {:ok, token} or {:error, reason}
  """
  @spec get_ident_email_token(String.t, String.t) :: {:ok, String.t} | {:error, String.t}
  def get_ident_email_token(email_addr, ident_pin_hash) do

  end

  # @doc """
  # Deletes from storage the ident_email_info corresponding to the given
  # `email_addr`.
  # """
  # @spec delete_ident_email_info(String.t) :: {:ok, :ok} | {:error, String.t}
  # def delete_ident_email_info(email_addr) do
  #
  # end
end
