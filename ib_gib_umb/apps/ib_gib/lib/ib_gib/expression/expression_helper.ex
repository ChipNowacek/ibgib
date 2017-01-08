defmodule IbGib.Expression.ExpressionHelper do
  @moduledoc """
  Helper methods specific to Expressions only.

  For any globally useful helper functions, see `IbGib.Helper`.
  """

  import Enum
  require Logger

  alias IbGib.Helper

  use IbGib.Constants, :ib_gib

  def add_rel8ns(this_info, rel8n_names, other_ib_gib)
  def add_rel8ns(this_info, rel8n_names, other_ib_gib)
    when length(rel8n_names) > 0 do
    # Create the new rel8ns. For each rel8n name that we are adding, we need
    # to check if that rel8n name itself already exists. If it does, then we
    # need to check if other_ib_gib doesn't already exist in it. If it does,
    # then we don't do anything since it's already rel8d with by that rel8n.
    # If it doesn't, then append the other_ib_gib.
    # If the rel8n itself doesn't even exist yet, we can simply add it to the
    # rel8n map, e.g. add `"rel8n" => [other_ib_gib]` to rel8ns.
    new_rel8ns =
      rel8n_names
      |> Enum.reduce(this_info[:rel8ns], fn(rel8n, acc) ->
           if Map.has_key?(acc, rel8n) do
              if Enum.member?(acc[rel8n], other_ib_gib) do
                # The rel8n already exists with the other_ib_gib, so don't add
                # it again (which would duplicate it).
                acc
              else
                # The rel8n exists, but not yet with other_ib_gib, so append it.
                Map.put(acc, rel8n, acc[rel8n] ++ [other_ib_gib])
              end
           else
             # The rel8n doesn't exist, so add it with the sole rel8n to
             # other_ib_gib
             Map.put_new(acc, rel8n, [other_ib_gib])
           end
         end)

    # Overwrite the existing rel8ns with new_rel8ns.
    Map.put(this_info, :rel8ns, new_rel8ns)
  end
  def add_rel8ns(this_info, _rel8n_names, _other_ib_gib) do
    # rel8n_names is empty list (or invalid)
    this_info
  end

  def remove_rel8ns(this_info, rel8n_names, other_ib_gib)
  def remove_rel8ns(this_info, rel8n_names, other_ib_gib)
    when length(rel8n_names) > 0 do
      _ = Logger.warn("yoooooooooooooooooooooooooooooo what up?")
      _ = Logger.debug("this_info:\n#{inspect this_info}" |> ExChalk.bg_blue |> ExChalk.red)
      _ = Logger.debug("rel8n_names: #{inspect rel8n_names}" |> ExChalk.bg_blue |> ExChalk.red)
      _ = Logger.debug("other_ib_gib: #{inspect other_ib_gib}" |> ExChalk.bg_blue |> ExChalk.red)
    # For each rel8n name that we are removing, we need
    # to check if that rel8n name exists. If it does, then we
    # need to check if other_ib_gib exists in it. If it does, then remove it.
    # If it doesn't, then log and continue
    # If it was the last rel8n (besides the root), then remove the rel8n itself.
    new_rel8ns =
      rel8n_names
      |> Enum.reduce(this_info[:rel8ns], fn(rel8n, acc) ->
           if Enum.member?(@invalid_unrel8_rel8ns, rel8n) do
             _ = Logger.warn "Tried to remove rel8n (#{rel8n}) from invalid rel8n list (#{inspect @invalid_unrel8_rel8ns})."
             acc
           else
             if Map.has_key?(acc, rel8n) do
                if Enum.member?(acc[rel8n], other_ib_gib) do
                  # The rel8n exists with the other_ib_gib, so remove it
                  new_rel8n_list = acc[rel8n] -- [other_ib_gib]
                  # contains_root? = Enum.member?(new_rel8n_list, @root_ib_gib)
                  if Enum.empty?(new_rel8n_list) do
                    # There are no other rel8d ib_gib via this rel8n
                    Map.delete(acc, rel8n)
                  else
                    # There are still other ib_gib rel8d via this rel8n
                    Map.put(acc, rel8n, new_rel8n_list)
                  end
                else
                  # The rel8n doesn't exist, so log and skip
                  _ = Logger.warn "Tried to remove rel8n (#{rel8n}) to other_ib_gib (#{other_ib_gib}). Rel8n exists, but not to that ib_gib."
                  acc
                end
             else
               # The rel8n doesn't exist, so log and skip
               _ = Logger.warn "Tried to remove rel8n (#{rel8n}) that doesn't exist in the ib_gib"
               acc
             end
           end
         end)

    # Overwrite the existing rel8ns with new_rel8ns.
    Map.put(this_info, :rel8ns, new_rel8ns)
  end
  def remove_rel8ns(this_info, _rel8n_names, _other_ib_gib) do
    # rel8n_names is empty list (or invalid)
    this_info
  end


  # `a` is the ib_gib info map with a key `:rel8ns` which is itself a map
  # in the form of "relation_name" => [ib^gib1, ib^gib2, ...ib^gibn]. This
  # adds to that map using the given `relation_name` and given `b`, which is
  # an `ib_gib` identifier (not the info map) or an array of `ib_gib`.
  #
  # ## Examples (not doc tests though, because is private)
  #     iex> a_info = %{ib: "some ib", gib: "some_gib", rel8ns: %{"ancestor" => ["ib^gib"]}}
  #     ...> relation_name = "ancestor"
  #     ...> b = "ib b^gib_b"
  #     ...> add_rel8n(a_info, relation_name, b)
  #     %{ib: "some ib", gib: "some_gib", rel8ns: %{"ancestor" => ["ib^gib", "ib b^gib_b"]}}
  def add_rel8n(a_info, relation_name, b)
  def add_rel8n(a_info, relation_name, b) when is_map(a_info) and is_bitstring(relation_name) and is_bitstring(b) do
    # _ = Logger.debug "bitstring yo"
    add_rel8n(a_info, relation_name, [b])
  end
  def add_rel8n(a_info, relation_name, b)
    when is_map(a_info) and is_bitstring(relation_name) and is_list(b) do
      _ = Logger.debug "a_info:\n#{inspect a_info, pretty: true}\nb:\n#{inspect b, pretty: true}"
    b_is_list_of_ib_gib =
      b |> all?(fn(item) -> Helper.valid_ib_gib?(item) end)

    if b_is_list_of_ib_gib do
      _ = Logger.debug "Adding relation #{relation_name} to a_info. a_info[:rel8ns]: #{inspect a_info[:rel8ns]}"
      a_relations = a_info[:rel8ns]

      relation_list = Map.get(a_relations, relation_name, [])

      new_relation_list =
        b
        |> Enum.reduce(relation_list, fn(rel, acc) ->
             if Enum.member?(acc, rel), do: acc, else: acc ++ [rel]
           end)

      new_a_relations = Map.put(a_relations, relation_name, new_relation_list)
      new_a = Map.put(a_info, :rel8ns, new_a_relations)
      _ = Logger.debug "Added relation #{relation_name} to a_info. a_info[:rel8ns]: #{inspect a_info[:rel8ns]}"
      new_a
    else
      _ = Logger.debug "Tried to add relation list of non-valid ib_gib."
      a_info
    end
  end
  def add_rel8n(a_info, relation_name, b) when is_map(a_info) and is_bitstring(relation_name) and is_map(b) do
    # _ = Logger.debug "mappy mappy"
    b_ib_gib = Helper.get_ib_gib!(b[:ib], b[:gib])
    add_rel8n(a_info, relation_name, [b_ib_gib])
  end
end
