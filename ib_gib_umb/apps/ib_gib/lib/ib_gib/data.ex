defmodule IbGib.Data do
  require Logger
  alias IbGib.Data.Schemas.IbGibModel
  alias IbGib.Data.Repo

  def save(info) when is_map(info) do
    # I can't figure out how to do a multi-line with clause!
    with {:ok, _model} <- insert_into_repo(info),
         {:ok, :ok}    <- IbGib.Data.Cache.put(IbGib.Helper.get_ib_gib!(info[:ib], info[:gib]), info) do
        {:ok, :ok}
    else
      # Need to improve this. :X
      # {:error, :already} -> {:ok, :ok}
      # {:error, changeset} ->
      #   {:error, "Save failed. changeset: #{inspect changeset}"}
      failure -> {:error, "Save failed: #{inspect failure}"}
    end
  end

  def save!(info) when is_map(info) do
    Logger.warn "info: #{inspect info}"
    case save(info) do
      {:ok, :ok} -> :ok
      {:error, :already} ->
        Logger.info "Tried to save info data that already exists."
        :ok
      {:error, reason} -> raise reason
    end
  end

  def load(ib, gib) when is_bitstring(ib) and is_bitstring(gib) do
    key = IbGib.Helper.get_ib_gib!(ib, gib)
    # For now, simply gets the value from the cache
    IbGib.Data.Cache.get(key)
  end

  def load!(ib, gib) when is_bitstring(ib) and is_bitstring(gib) do
    case load(ib, gib) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Inserts ib_gib info into the repo.

  Returns {:ok, model} or {:error, changeset}
  """
  defp insert_into_repo(info) when is_map(info) do
    Logger.debug "inserting into repo. info: #{inspect info}"
    changeset =
      IbGibModel.changeset(%IbGibModel{}, %{
        ib: info[:ib],
        gib: info[:gib],
        data: info[:data],
        rel8ns: info[:rel8ns]
      })
      |> Repo.insert
  end
end
