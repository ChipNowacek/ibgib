defmodule IbGib.Expression.Apply do
  @moduledoc """
  Apply functions used in `IbGib.Expression`.
  """

  import Enum
  require Logger

  alias IbGib.{Auth.Authz, Expression, Helper}
  alias IbGib.Transform.Mut8.Factory, as: Mut8Factory

  import IbGib.Macros
  import IbGib.Expression.ExpressionHelper

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  # ----------------------------------------------------------------------------
  # Apply Functions
  # We are within an init of a new process, and we are applying the given `b`
  # ib_gib info map (transform/query) to a given `a` "starting point" ib_gib
  # info map.
  #
  # This is where we actually **generate** "new" ib_gib.
  # _(aside from the transforms themselves which are also technically ib_gib)_
  #
  # See moduledoc for more details.
  # ----------------------------------------------------------------------------

  def apply_yo(a, b) when is_map(a) and is_map(b) do
    if b[:ib] == "query" and b[:gib] != "gib" do
      with(
        {:ok, %{:info => this_info} = state} <- apply_query(a, b),
        {:ok, this_ib_gib} <- Helper.get_ib_gib(this_info),
        :ok <- IbGib.Expression.Registry.register(this_ib_gib, self()),
        {:ok, :ok} <- Expression.set_life_timeout(:query)
      ) do
        {:ok, state}
      else
        error -> Helper.default_handle_error(error)
      end
    else
      invalid_args({:apply, {a, b}})
    end
  end

  def apply_fork(a, b) do
    _ = Logger.debug "applying fork b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    _ = Logger.debug "a[:rel8ns]: #{inspect a[:rel8ns]}"

    # First authorize
    b_identities = Authz.authorize_apply_b(:fork, a[:rel8ns], b[:rel8ns])

    fork_data = b[:data]

    # We're going to populate this with data from `a` and `b`.
    this_info = %{}

    # We take the ib directly from the fork's `dest_ib`.
    this_ib = fork_data["dest_ib"]
    this_info = Map.put(this_info, :ib, this_ib)

    a_ancestor = Map.get(a[:rel8ns], "ancestor", [])
    this_rel8ns = Map.merge(a[:rel8ns], %{"past" => @default_past})
    this_rel8ns = Map.put(this_rel8ns, "identity", b_identities)
    _ = Logger.debug "this_rel8ns: #{inspect this_rel8ns}"

    this_info = Map.put(this_info, :rel8ns, this_rel8ns)
    _ = Logger.debug "this_info: #{inspect this_info}"

    # We add the fork itself to the relations `dna`.
    this_info = this_info |> add_rel8n("dna", b)
    _ = Logger.debug "fork_data[\"src_ib_gib\"]: #{fork_data["src_ib_gib"]}"


    this_info =
      if a_ancestor == [@root_ib_gib] and a[:ib] == "ib" and a[:gib] == "gib" do
        # Don't add a duplicate ib^gib ancestor
        this_info
      else
        # Add fork src as ancestor
        this_info |> add_rel8n("ancestor", fork_data["src_ib_gib"])
      end

    _ = Logger.debug "this_info: #{inspect this_info}"

    # Copy the data over. Data is considered to be "small", so should be
    # copyable.
    this_data = Map.get(a, :data, %{})
    this_info = Map.put(this_info, :data, this_data)
    _ = Logger.debug "this_info: #{inspect this_info}"

    # Now we calculate the new hash and set it to `:gib`.
    this_gib = Helper.hash(this_ib, this_info[:rel8ns], this_data)
    this_gib =
      if Helper.gib_stamped?(b[:gib]) do
        Helper.stamp_gib!(this_gib)
      else
        this_gib
      end
    this_info = Map.put(this_info, :gib, this_gib)
    _ = Logger.debug "this_info: #{inspect this_info}"

    {:ok, {this_ib, this_gib, this_info}}
  end

  def apply_mut8(a, b) do
    # We are applying a mut8 transform.
    _ = Logger.debug "applying mut8 b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    _ = Logger.debug "a[:rel8ns]: #{inspect a[:rel8ns]}"

    # First authorize
    b_identities = Authz.authorize_apply_b(:mut8, a[:rel8ns], b[:rel8ns])

    # We're going to borrow `a` as our own info for the new thing. We're just
    # going to change its `gib`, and `relations`, and its `data` since it's
    # a mut8 transform.

    # the ib stays the same
    ib = a[:ib]
    original_gib = a[:gib]
    original_ib_gib = Helper.get_ib_gib!(ib, original_gib)
    _ = Logger.debug "retaining ib. a[:ib]...: #{ib}"

    # Passed authorization.
    # I do not call add_rel8n for this, because I want it to overwrite.
    a_rel8ns = Map.put(a[:rel8ns], "identity", b_identities)
    a = Map.put(a, :rel8ns, a_rel8ns)

    # We add the mut8 itself to the `relations`.
    a =
      a
      |> add_rel8n("past", original_ib_gib)
      |> add_rel8n("dna", b)

    a_data = Map.get(a, :data, %{})
    b_data = Map.get(b, :data, %{})
    _ = Logger.debug "a_data: #{inspect a_data}\nb_data: #{inspect b_data}"

    b_new_data_metadata =
      b_data["new_data"]
      |> Enum.filter(fn(entry) ->
         _ = Logger.debug "creating metadata. entry: #{inspect entry}"
           _ = Logger.debug "entry: #{inspect entry}"
           {entry_key, _} = entry
           entry_key |> String.starts_with?(@map_key_meta_prefix)
         end)
      |> Enum.reduce(%{}, fn(entry, acc) ->
           {key, value} = entry
           acc |> Map.put(key, value)
         end)
    _ = Logger.debug "b_new_data_metadata: #{inspect b_new_data_metadata}"

    a_data = a_data |> apply_mut8_metadata(b_new_data_metadata)
    _ = Logger.debug "a_data: #{inspect a_data}"

    b_new_data =
      b_data["new_data"]
      |> Enum.filter(fn(entry) ->
           _ = Logger.debug "creating data without metadata. entry: #{inspect entry}"
           {entry_key, _} = entry
           !String.starts_with?(entry_key, @map_key_meta_prefix)
         end)
      |> Enum.reduce(%{}, fn(entry, acc) ->
           {key, value} = entry
           acc |> Map.put(key, value)
         end)
    _ = Logger.debug "b_new_data: #{inspect b_new_data}"
    _ = Logger.debug "a_data: #{inspect a_data}"

    merged_data =
      if map_size(b_new_data) > 0 do
        Map.merge(a_data, b_new_data)
      else
        a_data
      end

    _ = Logger.debug "merged data: #{inspect merged_data}"
    a = Map.put(a, :data, merged_data)

    # Now we calculate the new hash and set it to `:gib`.
    this_gib = Helper.hash(ib, a[:rel8ns], merged_data)
    this_gib =
      if Helper.gib_stamped?(b[:gib]) do
        Helper.stamp_gib!(this_gib)
      else
        this_gib
      end
    _ = Logger.debug "this_gib: #{this_gib}"
    a = Map.put(a, :gib, this_gib)

    _ = Logger.debug "a[:gib] set to gib: #{this_gib}"

    {:ok, {ib, this_gib, a}}
  end

  def apply_mut8_metadata(a_data, b_new_data_metadata)
    when map_size(b_new_data_metadata) > 0 do
    _ = Logger.debug "a_data start: #{inspect a_data}"

    remove_key = Mut8Factory.get_meta_key(:mut8_remove_key)
    rename_key = Mut8Factory.get_meta_key(:mut8_rename_key)
    _ = Logger.debug "remove_key: #{remove_key}"
    _ = Logger.debug "rename_key: #{rename_key}"

    b_new_data_metadata
    |> Enum.reduce(a_data, fn(entry, acc) ->
         {key, value} = entry
         _ = Logger.debug "key: #{key}"
         cond do
           key === remove_key ->
             _ = Logger.debug "remove_key. {key, value}: {#{key}, #{value}}"
             _acc = Map.drop(acc, [value])

           key === rename_key ->
             _ = Logger.debug "rename_key. {key, value}: {#{key}, #{value}}"
             [old_key_name, new_key_name] = String.split(value, @rename_operator)
             _ = Logger.debug "old_key_name: #{old_key_name}, new: #{new_key_name}"
             data_value = a_data |> Map.get(old_key_name)
             _acc =
               acc
               |> Map.drop([old_key_name])
               |> Map.put(new_key_name, data_value)

           true ->
             _ = Logger.error "Unknown mut8_metadata key: #{key}"
             a_data
         end
       end)
  end
  def apply_mut8_metadata(a_data, b_new_data_metadata)
    when map_size(b_new_data_metadata) === 0 do
    a_data
  end

  def apply_rel8(a, b) do
    # We are applying a rel8 transform.
    _ = Logger.debug "applying rel8 b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    _ = Logger.debug "a[:rel8ns]: #{inspect a[:rel8ns]}"

    # First authorize
    b_identities = Authz.authorize_apply_b(:rel8, a[:rel8ns], b[:rel8ns])

    # Make sure that we are the correct src_ib_gib. Fail fast if we aren't,
    # since we're within a new process attempting to init.
    a_ib_gib = Helper.get_ib_gib!(a[:ib], a[:gib])
    src_ib_gib = b[:data]["src_ib_gib"]
    if a_ib_gib != src_ib_gib do
      emsg = emsg_invalid_rel8_src_mismatch(src_ib_gib, a_ib_gib)
      _ = Logger.error emsg
      raise IbGib.InvalidRel8Error, emsg
    end

    # We're going to populate this with data from `a` and `b`.
    this_info = %{}

    # Keep the same ib and data
    this_ib = a[:ib]
    this_data = a[:data]
    this_info =
      this_info
      |> Map.put(:ib, this_ib)
      |> Map.put(:data, this_data)


    # Before adding the rel8ns specified in the transform b, we need to add the
    # transform itself to the dna and the existing ib_gib to the past.
    this_info =
      this_info
      |> Map.put(:rel8ns, a[:rel8ns])
      |> add_rel8n("past", a)
      |> add_rel8n("dna", b)
      |> add_rel8n("identity", b_identities)

    # Add/Remove the rel8ns
    # If the rel8n starts with a minus (-), then we're removing the rel8n.

    # This is the ib_gib to which we will rel8.
    other_ib_gib = b[:data]["other_ib_gib"]
    rel8n_names = b[:data]["rel8ns"]

    # Set empty/nil rel8ns to defaults
    rel8n_names =
      case rel8n_names do
        nil -> @default_rel8ns
        [] -> @default_rel8ns
        valid_rel8n_names -> valid_rel8n_names
      end
    _ = Logger.debug "rel8n_names: #{inspect rel8n_names}"

    rel8n_names_to_add =
      rel8n_names
      |> Enum.filter(fn(r_name) -> !String.starts_with?(r_name, "-") end)
    rel8n_names_to_remove =
      rel8n_names
      |> Enum.filter(fn(r_name) ->
           String.starts_with?(r_name, "-") and !Enum.member?(@invalid_unrel8_rel8ns, r_name)
         end)

    # Execute the add/remove on the `this_info` map
    this_info =
      this_info
      |> add_rel8ns(rel8n_names_to_add, other_ib_gib)
      |> remove_rel8ns(rel8n_names_to_remove, other_ib_gib)

    this_rel8ns = this_info[:rel8ns]
    _ = Logger.debug "New rel8ns. this_rel8ns: #{inspect this_rel8ns}"

    # Now we calculate the new hash and set it to `:gib`.
    this_gib = Helper.hash(this_ib, this_rel8ns, this_data)
    this_gib =
      if Helper.gib_stamped?(b[:gib]) do
        Helper.stamp_gib!(this_gib)
      else
        this_gib
      end
    _ = Logger.debug "this_gib: #{this_gib}"

    this_info = Map.put(this_info, :gib, this_gib)

    _ = Logger.debug "a[:gib] set to gib: #{a[:gib]}"

    {:ok, {this_ib, this_gib, this_info}}
  end

  def apply_query(a, b) do
    _ = Logger.debug "a: #{inspect a}\nb: #{inspect b}"
    b_identities = Authz.authorize_apply_b(:query, a[:rel8ns], b[:rel8ns])

    query_options = b[:data]["options"]
    result = IbGib.Data.query(query_options)
    _ = Logger.debug "query result: #{inspect result}"

    this_info = %{}
    this_ib = "query_result"
    this_info = Map.put(this_info, :ib, this_ib)
    result_count =
      if Enum.any?(result, &(&1.ib == "ib" and &1.gib == "gib")) do
        Enum.count(result)
      else
        # all results will include ib^gib
        Enum.count(result) + 1
      end
    this_data = %{"result_count" => "#{result_count}"}
    this_rel8ns = %{
      "dna" => @default_dna,
      "ancestor" => @default_ancestor ++ ["query_result#{@delim}gib"],
      "past" => @default_past,
      "identity" => b_identities
    }
    this_info =
      this_info
      |> Map.put(:ib, this_ib)
      |> Map.put(:data, this_data)
      |> Map.put(:rel8ns, this_rel8ns)
      |> add_rel8n("dna", b)
      |> add_rel8n("query", b)
      |> add_rel8n(
          "result",
          result |> reduce(["ib#{@delim}gib"], fn(ib_gib_model, acc) ->
            acc ++ [Helper.get_ib_gib!(ib_gib_model.ib, ib_gib_model.gib)]
          end))

    this_gib = Helper.hash(this_ib, this_info[:rel8ns], this_info[:data])
    this_info = Map.put(this_info, :gib, this_gib)

    _ = Logger.debug "this_info is built yo! this_info: #{inspect this_info}"

    with(
      # {:ok, ib_gib} <- Helper.get_ib_gib(this_ib, this_gib),
      {:ok, :ok} <- IbGib.Data.save(this_info)
    ) do
      _ = Logger.debug "Saved and registered ok. this_info: #{inspect this_info}"
      {:ok, %{:info => this_info}}
    else
      {:error, result} ->
        _ = Logger.error "Save/Register error result: #{inspect result}"
        {:error, result}
      error ->
        _ = Logger.error "Save/Register error: #{inspect error}"
        {:error, error}
    end
  end

end
