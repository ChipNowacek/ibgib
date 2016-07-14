defmodule IbGib.Data do
  def save(info) when is_map(info) do
    key = IbGib.Helper.get_ib_gib!(info[:ib], info[:gib])
    # For now, this simply puts it in the cache
    IbGib.Cache.put(key, info)
  end

  def save!(info) when is_map(info) do
    case save(info) do
      :ok -> :ok
      {:error, reason} -> raise reason
    end
  end

  def load(ib, gib) when is_bitstring(ib) and is_bitstring(gib) do
    key = IbGib.Helper.get_ib_gib!(ib, gib)
    # For now, simply gets the value from the cache
    IbGib.Cache.get(key)
  end

  def load!(ib, gib) when is_bitstring(ib) and is_bitstring(gib) do
    case load(ib, gib) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end
end
