defmodule IbGib.Data do
  require Logger

  def save(info) when is_map(info) do
    key = IbGib.Helper.get_ib_gib!(info[:ib], info[:gib])
    # For now, this simply puts it in the cache
    IbGib.Data.Cache.put(key, info)
  end

  def save!(info) when is_map(info) do
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
end
