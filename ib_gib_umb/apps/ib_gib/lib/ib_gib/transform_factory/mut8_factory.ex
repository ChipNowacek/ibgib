defmodule IbGib.TransformFactory.Mut8Factory do
  @moduledoc """
  This factory module creates `new_data` maps to be used when mut8ng ib_gib with
  `IbGib.Expression.mut8/2`.
  """

  alias IbGib.Helper
  use IbGib.Constants, :ib_gib

  @doc """
  Creates a new_data map with the given `key` => `value`.

  See `IbGib.Expression.mut8/2`.
  """
  @spec add_or_update_key(String.t, String.t) :: map
  def add_or_update_key(key, value)
    when is_bitstring(key) and is_bitstring(value) do
    %{key => value}
  end

  @doc """
  Creates a new_data map to indicate removing the given `key_to_remove`.

  See `IbGib.Expression.mut8/2`.
  """
  @spec remove_key(String.t) :: map
  def remove_key(key_to_remove)
    when is_bitstring(key_to_remove) do
    %{get_meta_key(:mut8_remove_key) => key_to_remove}
  end

  @doc """
  Creates a new_data map to indicate renaming the given `old_key_name` to
  `new_key_name`.

  See `IbGib.Expression.mut8/2`.
  """
  @spec rename_key(String.t, String.t) :: map
  def rename_key(old_key_name, new_key_name)
    when is_bitstring(old_key_name) and is_bitstring(new_key_name) do
    %{
      get_meta_key(:mut8_rename_key) =>
        old_key_name <> rename_operator <> new_key_name
    }
  end

  @doc """
  Creates a "meta_key" that will be used in a mut8 transform.

  See `remove_key/1` and `rename_key/2`.
  See `IbGib.Expression.mut8/2`.
  """
  @spec get_meta_key(atom) :: String.t
  def get_meta_key(which)
  def get_meta_key(:mut8_remove_key) do
    map_key_meta_prefix <> "remove_key"
  end
  def get_meta_key(:mut8_rename_key) do
    map_key_meta_prefix <> "rename_key"
  end
end
