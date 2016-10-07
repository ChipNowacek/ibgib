defmodule WebGib.Data do
  @moduledoc """
  Facade to working with WebGib Data (Repo).

  My original use case for this is storing tokens when logging in via email.
  """

  require Logger
  import Ecto.Query

  alias WebGib.Data.Repo
  alias WebGib.Data.Schemas.TokenModel

  use IbGib.Constants, :error_msgs

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
    _ = Logger.debug("email_addr: #{email_addr}" |> ExChalk.magenta)
    insert_result =
      %TokenModel{}
      |> TokenModel.changeset(%{
           email_addr: email_addr,
           token: token,
           ident_pin_hash: ident_pin_hash
         })
      |> Repo.insert

    _ = Logger.debug("after insert" |> ExChalk.magenta)

    case insert_result do
      {:ok, _model} ->
        _ = Logger.debug "Inserted token for email_addr: #{email_addr}"
        {:ok, :ok}

      {:error, changeset} ->
        emsg = "Error inserting token with email address #{email_addr}"
        _ = Logger.error emsg
        _ = Logger.error("changeset:\n#{inspect changeset}")
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
    with(
      # Try to get the model from the repo, but only if the proper
      # ident_pin_hash is given in tandem with the email_addr.
      model <- get_from_repo(email_addr, ident_pin_hash),

      # Get the token from the model (maybe overkill here)
      {:ok, token} <- get_token_from_model(model),

      # Delete after any attempt to retrieve the email_addr. If there are any
      # problems, the entire workflow should be restarted. This is the strategy
      # since it is assumed that this workflow is cheap and that there should
      # be relatively few needs for retries.
      {:ok, :ok} <- delete_if_exists(email_addr)
    ) do
      {:ok, token}
    else
      {:error, reason} when is_bitstring(reason) -> {:error, reason}
      {:error, reason} -> {:error, inspect reason}
      error -> {:error, inspect error}
    end
  end

  defp get_from_repo(email_addr, ident_pin_hash) do
    _ = Logger.debug("getting model. email_addr: #{email_addr}" |> ExChalk.magenta)

    model =
      TokenModel
      |> where(email_addr: ^email_addr, ident_pin_hash: ^ident_pin_hash)
      |> select([:id, :token])
      |> Repo.one

    _ = Logger.debug "got model: #{inspect model}"
    model
  end

  defp get_token_from_model(model) do
    cond do
      model == nil -> {:error, emsg_not_found("model")}
      model.token == nil -> {:error, emsg_not_found("model token")}
      true -> {:ok, model.token}
    end
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
