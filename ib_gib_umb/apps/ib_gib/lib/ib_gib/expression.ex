defmodule IbGib.Expression do
  @moduledoc """
  This is the primary module right now for the IbGib engine. Basically an
  `IbGib.Expression` encapsulates functionality for "expressing" ib_gib.

  For starters, you can think of ib_gib as "things" or "objects". The term also
  will refer to the "name" of a "thing" or "object", represented by an "id"
  (the `ib`) and the "hash" (the `gib`).

  "Expression" is the process of how we get "new" and "existing" ib_gib. If we
  express an ib_gib that already exists in our repo, for instance, then it
  will create an `IbGib.Expression` process (supervised by the
  `IbGib.Expression.Supervisor`) and hydrate its state from the repo. If we
  are creating a "new" ib_gib or "mutating" an existing ib_gib, or are
  executing some other action upon an existing ib_gib, then the expression
  process will create the appropriate transform ib_gib (and processes) and then
  generate the resultant ib_gib (and process(es)). While doing this, it
  automatically saves each ib_gib's state in the repo.

  ## Init Functions
  In in the init stage, an expression either loads existing information from
  the `IbGib.Data.Repo` or `IbGib.Data.Cache`, or it does the work of two
  ib_gib coming into contact with each other (see the Apply Functions).

  ## Apply Functions
  These functions are called within init functions on new expressions. Here,
  we take the first ib_gib info (`a`) as our "starting point", and then we
  "apply" `b`, which for starters are pretty much transforms: `fork`, `mut8`,
  and `rel8`. When applying a query, I am not sure how the `a` will come into
  play, but initially it will be pretty much ignored (I think).

  So these apply functions actually perform the "work" of combining two ib_gib.

  ## Basic Client API Functions: `fork`, `mut8`, and `rel8`
  Each expression process is the state of an ib_gib. The client API functions
  expose functions for the basic, hard-coded transforms that can be executed
  using that ib_gib state. These include `fork`, `mut8`, `rel8`. There are also
  a couple other functions ATOW (2016/08/13): `query` and `instance`.

  The basic workflow is this (I'll use a fork as the example):

  1. Create the fork transform based off of the source expression, save that
     transform, and create a new running process with that transform's state.

     So at this point, we have the source expression and a new fork transform
     expression process, with each's state already persisted to the repo.

  2. Bring the transform "into contact" with the source expression, which will
     create a tertiary ib_gib process. During init, this new process will
     generate its own state that is a combination of the source and the
     transform, thus "applying" the transform.

     So, basically, we've created a third ib_gib that is the result of combining
     our transform and the source. So we will have in the end, the source
     ib_gib process, a "fork" transform ib_gib process, and the resulting
     "forked" ib_gib process. In the fork's instance, this new process will have
     a new `ib`, new `gib`, the same (internal) `data`, and slightly different
     `rel8ns`, including the source as an "ancestor" of the forked process.
  """

  use GenServer
  require Logger
  import Enum

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs
  import IbGib.Macros
  alias IbGib.{TransformFactory, Helper, TransformFactory.Mut8Factory}
  alias IbGib.UnauthorizedError
  alias IbGib.TransformBuilder, as: TB

  # ----------------------------------------------------------------------------
  # Constructors
  # ----------------------------------------------------------------------------
  @doc """
  Starts an expression via given `args` as follows:

    {:ib_gib, {ib, gib}} - Use this to start an expression for an existing
      `ib_gib` that has already been persisted. the `ib` and `gib` uniquely
      identify something in time.

    {:apply, {a, b}} - Use this to create a new ib_gib, usually when applying
      a transform ib_gib `b` to some other ib_gib `a`.
  """
  def start_link(args)
  def start_link({:ib_gib, {ib, gib}}) do
    # expr_id = Helper.new_id |> String.downcase
    Logger.debug "{ib, gib}: {#{inspect ib}, #{inspect gib}}"
    GenServer.start_link(__MODULE__, {:ib_gib, {ib, gib}})
  end
  def start_link({:apply, {a, b}}) when is_map(a) and is_map(b) do
    # expr_id = Helper.new_id |> String.downcase
    Logger.debug "a: {#{inspect a}\nb: #{inspect b}}"
    GenServer.start_link(__MODULE__, {:apply, {a, b}})
  end
  def start_link({:express, {identity_ib_gibs, a, a_info, b}})
    when is_bitstring(a) and (is_map(a_info) or is_nil(a_info)) and
         is_bitstring(b) do
    Logger.debug "express. a: {#{a}\nb: #{b}}"
    GenServer.start_link(__MODULE__, {:express, {identity_ib_gibs, a, a_info, b}})
  end


  # ----------------------------------------------------------------------------
  # Inits
  # ----------------------------------------------------------------------------

  # We are loading a pre-existing ib_gib.
  def init({:ib_gib, {ib, gib}}) when is_bitstring(ib) and is_bitstring(gib) do
    Logger.metadata([x: :ib_gib])
    info =
      case {ib, gib} do
        {"ib", "gib"} -> init_default(:root)
        {"fork", "gib"} -> init_default(:fork)
        {"mut8", "gib"} -> init_default(:mut8)
        {"rel8", "gib"} -> init_default(:rel8)
        {"query", "gib"} -> init_default(:query)
        _ -> IbGib.Data.load!(ib, gib)
      end
    register_result = IbGib.Expression.Registry.register(Helper.get_ib_gib!(ib, gib), self)
    if register_result == :ok do
      {:ok, %{:info => info}}
    else
      Logger.error "Register expression error: #{inspect register_result}"
      {:error, register_result}
    end
  end
  # Creating a "new" ib_gib from two existing ib_gib by "applying" b to a.
  def init({:apply, {a, b}}) when is_map(a) and is_map(b) do
    Logger.metadata([x: :apply])

    case {b[:ib], b[:gib]} do
      {"fork", b_gib} when b_gib != "gib" -> apply_fork(a, b)
      {"mut8", b_gib} when b_gib != "gib" -> apply_mut8(a, b)
      {"rel8", b_gib} when b_gib != "gib" -> apply_rel8(a, b)
      {"query", b_gib} when b_gib != "gib" -> apply_query(a, b)
      {b_ib, b_gib} ->
        err_msg = "unknown combination: a: #{inspect a}, b: #{inspect b}"
        Logger.error err_msg
        {:error, err_msg}
    end
  end
  # Creating a "new" ib_gib from two existing ib_gib by "applying" b to a.
  # This is going to be replacing the :apply version I think. WIP.
  def init({:express, {identity_ib_gibs, a_ib_gib, a_info, b_ib_gib}})
    when is_bitstring(a_ib_gib) and is_bitstring(b_ib_gib) do
    Logger.metadata([x: :express])
    Logger.warn "11111111111111111111111"
    Logger.debug "express. identity_ib_gibs: #{inspect identity_ib_gibs}\na_ib_gib: #{a_ib_gib}\n, b_ib_gib: #{b_ib_gib}"

    # First, we just store our state with mama and papa ib_gib (and identities)
    # state = %{"expressed" => false, "a_info" => a_info}
    # I don't think any state is required...but maybe the expressed flag would be good.
    state = %{}

    {:ok, state}
  end

  # Note: Root maps to "ib". All of the others map to the string.
  defp init_default(:root), do: get_default("ib")
  defp init_default(:fork), do: get_default("fork")
  defp init_default(:mut8), do: get_default("mut8")
  defp init_default(:rel8), do: get_default("rel8")
  defp init_default(:query), do: get_default("query")

  # Builds the default ib_gib structure for "primitive"-like ib_gib.
  defp get_default(ib_string) when is_bitstring(ib_string) do
    Logger.debug "initializing ib_gib #{ib_string} expression."
    %{
      :ib => ib_string,
      :gib => "gib",
      :rel8ns => %{
        "dna" => @default_dna,
        "ancestor" => @default_ancestor,
        "past" => @default_past,
        "identity" => @default_identity
        },
      :data => @default_data
    }
  end

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

  defp apply_fork(a, b) do
    Logger.debug "applying fork b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    Logger.debug "a[:rel8ns]: #{inspect a[:rel8ns]}"

    # First authorize
    b_identities = authorize_apply_b(:fork, a[:rel8ns], b[:rel8ns])

    fork_data = b[:data]

    # We're going to populate this with data from `a` and `b`.
    this_info = %{}

    # We take the ib directly from the fork's `dest_ib`.
    this_ib = fork_data["dest_ib"]
    this_info = Map.put(this_info, :ib, this_ib)

    # rel8ns is tricky. Should we by default keep rel8ns except past?
    # Or should we reset and only bring over `dna` and `ancestor`? Others?
    # tricky...
    a_dna = Map.get(a[:rel8ns], "dna", [])
    a_ancestor = Map.get(a[:rel8ns], "ancestor", [])
    this_rel8ns = Map.merge(a[:rel8ns], %{"past" => @default_past})
    this_rel8ns = Map.put(this_rel8ns, "identity", b[:rel8ns]["identity"])
    Logger.debug "this_rel8ns: #{inspect this_rel8ns}"

    this_info = Map.put(this_info, :rel8ns, this_rel8ns)
    Logger.debug "this_info: #{inspect this_info}"

    # We add the fork itself to the relations `dna`.
    this_info = this_info |> add_rel8n("dna", b)
    Logger.debug "fork_data[\"src_ib_gib\"]: #{fork_data["src_ib_gib"]}"


    this_info =
      if a_ancestor == [@root_ib_gib] and a[:ib] == "ib" and a[:gib] == "gib" do
        # Don't add a duplicate ib^gib ancestor
        this_info
      else
        # Add fork src as ancestor
        this_info |> add_rel8n("ancestor", fork_data["src_ib_gib"])
      end

    Logger.debug "this_info: #{inspect this_info}"

    # Copy the data over. Data is considered to be "small", so should be
    # copyable.
    this_data = Map.get(a, :data, %{})
    this_info = Map.put(this_info, :data, this_data)
    Logger.debug "this_info: #{inspect this_info}"

    # Now we calculate the new hash and set it to `:gib`.
    this_gib = Helper.hash(this_ib, this_info[:rel8ns], this_data)
    this_gib =
      if Helper.gib_stamped?(b[:gib]) do
        Helper.stamp_gib!(this_gib)
      else
        this_gib
      end
    this_info = Map.put(this_info, :gib, this_gib)
    Logger.debug "this_info: #{inspect this_info}"

    {:ok, {this_ib, this_gib, this_info}}
    # on_new_expression_completed(this_ib, this_gib, this_info)
  end

  defp apply_mut8(a, b) do
    # We are applying a mut8 transform.
    Logger.debug "applying mut8 b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    Logger.debug "a[:rel8ns]: #{inspect a[:rel8ns]}"

    # First authorize
    b_identities = authorize_apply_b(:mut8, a[:rel8ns], b[:rel8ns])

    # We're going to borrow `a` as our own info for the new thing. We're just
    # going to change its `gib`, and `relations`, and its `data` since it's
    # a mut8 transform.

    # the ib stays the same
    ib = a[:ib]
    original_gib = a[:gib]
    original_ib_gib = Helper.get_ib_gib!(ib, original_gib)
    Logger.debug "retaining ib. a[:ib]...: #{ib}"

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
    Logger.debug "a_data: #{inspect a_data}\nb_data: #{inspect b_data}"

    b_new_data_metadata =
      b_data["new_data"]
      |> Enum.filter(fn(entry) ->
         Logger.debug "creating metadata. entry: #{inspect entry}"
           Logger.debug "entry: #{inspect entry}"
           {entry_key, _} = entry
           entry_key |> String.starts_with?(map_key_meta_prefix)
         end)
      |> Enum.reduce(%{}, fn(entry, acc) ->
           {key, value} = entry
           acc |> Map.put(key, value)
         end)
    Logger.debug "b_new_data_metadata: #{inspect b_new_data_metadata}"

    a_data = a_data |> apply_mut8_metadata(b_new_data_metadata)
    Logger.debug "a_data: #{inspect a_data}"

    b_new_data =
      b_data["new_data"]
      |> Enum.filter(fn(entry) ->
           Logger.debug "creating data without metadata. entry: #{inspect entry}"
           {entry_key, _} = entry
           !String.starts_with?(entry_key, map_key_meta_prefix)
         end)
      |> Enum.reduce(%{}, fn(entry, acc) ->
           {key, value} = entry
           acc |> Map.put(key, value)
         end)
    Logger.debug "b_new_data: #{inspect b_new_data}"
    Logger.debug "a_data: #{inspect a_data}"

    merged_data =
      if map_size(b_new_data) > 0 do
        Map.merge(a_data, b_new_data)
      else
        a_data
      end

    Logger.debug "merged data: #{inspect merged_data}"
    a = Map.put(a, :data, merged_data)

    # Now we calculate the new hash and set it to `:gib`.
    this_gib = Helper.hash(ib, a[:rel8ns], merged_data)
    this_gib =
      if Helper.gib_stamped?(b[:gib]) do
        Helper.stamp_gib!(this_gib)
      else
        this_gib
      end
    Logger.debug "this_gib: #{this_gib}"
    a = Map.put(a, :gib, this_gib)

    Logger.debug "a[:gib] set to gib: #{this_gib}"

    {:ok, {ib, this_gib, a}}
    # on_new_expression_completed(ib, this_gib, a)
  end

  defp apply_mut8_metadata(a_data, b_new_data_metadata)
    when map_size(b_new_data_metadata) > 0 do
    Logger.debug "a_data start: #{inspect a_data}"

    remove_key = Mut8Factory.get_meta_key(:mut8_remove_key)
    rename_key = Mut8Factory.get_meta_key(:mut8_rename_key)
    Logger.debug "remove_key: #{remove_key}"
    Logger.debug "rename_key: #{rename_key}"

    b_new_data_metadata
    |> Enum.reduce(a_data, fn(entry, acc) ->
         {key, value} = entry
         Logger.debug "key: #{key}"
         cond do
           key === remove_key ->
             Logger.debug "remove_key. {key, value}: {#{key}, #{value}}"
             acc = Map.drop(acc, [value])

           key === rename_key ->
             Logger.debug "rename_key. {key, value}: {#{key}, #{value}}"
             [old_key_name, new_key_name] = String.split(value, rename_operator)
             Logger.debug "old_key_name: #{old_key_name}, new: #{new_key_name}"
             data_value = a_data |> Map.get(old_key_name)
             acc =
               acc
               |> Map.drop([old_key_name])
               |> Map.put(new_key_name, data_value)

           true ->
             Logger.error "Unknown mut8_metadata key: #{key}"
             a_data
         end
       end)
  end
  defp apply_mut8_metadata(a_data, b_new_data_metadata)
    when map_size(b_new_data_metadata) === 0 do
    a_data
  end

  defp apply_rel8(a, b) do
    # We are applying a rel8 transform.
    Logger.debug "applying rel8 b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    Logger.debug "a[:rel8ns]: #{inspect a[:rel8ns]}"

    # First authorize
    b_identities = authorize_apply_b(:rel8, a[:rel8ns], b[:rel8ns])

    # Make sure that we are the correct src_ib_gib. Fail fast if we aren't,
    # since we're within a new process attempting to init.
    a_ib_gib = Helper.get_ib_gib!(a[:ib], a[:gib])
    src_ib_gib = b[:data]["src_ib_gib"]
    if a_ib_gib != src_ib_gib do
      emsg = emsg_invalid_rel8_src_mismatch(src_ib_gib, a_ib_gib)
      Logger.error emsg
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
    this_rel8ns = this_info[:rel8ns]

    # Add the rel8ns
    # This is the ib_gib to which we will rel8.
    other_ib_gib = b[:data]["other_ib_gib"]
    rel8n_names = b[:data]["rel8ns"]

    rel8n_names =
      case rel8n_names do
        nil -> @default_rel8ns
        [] -> @default_rel8ns
        valid_rel8n_names -> valid_rel8n_names
      end
    Logger.debug "rel8n_names: #{inspect rel8n_names}"

    this_info =
      this_info |> add_rel8ns(rel8n_names, other_ib_gib)

    this_rel8ns = this_info[:rel8ns]
    Logger.debug "New rel8ns. this_rel8ns: #{inspect this_rel8ns}"

    # Now we calculate the new hash and set it to `:gib`.
    this_gib = Helper.hash(this_ib, this_rel8ns, this_data)
    this_gib =
      if Helper.gib_stamped?(b[:gib]) do
        Helper.stamp_gib!(this_gib)
      else
        this_gib
      end
    Logger.debug "this_gib: #{this_gib}"

    this_info = Map.put(this_info, :gib, this_gib)

    Logger.debug "a[:gib] set to gib: #{a[:gib]}"

    {:ok, {this_ib, this_gib, this_info}}
    # on_new_expression_completed(this_ib, this_gib, this_info)
  end

  defp add_rel8ns(this_info, rel8n_names, other_ib_gib) do
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

  defp apply_query(a, b) do
    Logger.debug "a: #{inspect a}\nb: #{inspect b}"
    b_identities = authorize_apply_b(:query, a[:rel8ns], b[:rel8ns])

    query_options = b[:data]["options"]
    result = IbGib.Data.query(query_options)
    Logger.debug "query result: #{inspect result}"

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

    # who = IbGib.QueryOptionsFactory.get_identities(query_options)
    #
    # this_info =
    #   if who != nil do
    #     this_info
    #     |> add_rel8n("identity", who)
    #   else
    #     this_info
    #   end

    this_gib = Helper.hash(this_ib, this_info[:rel8ns], this_info[:data])
    this_info = Map.put(this_info, :gib, this_gib)

    Logger.debug "this_info is built yo! this_info: #{inspect this_info}"
    on_new_expression_completed(this_ib, this_gib, this_info)
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
  defp add_rel8n(a_info, relation_name, b)
  defp add_rel8n(a_info, relation_name, b) when is_map(a_info) and is_bitstring(relation_name) and is_bitstring(b) do
    # Logger.debug "bitstring yo"
    add_rel8n(a_info, relation_name, [b])
  end
  defp add_rel8n(a_info, relation_name, b)
    when is_map(a_info) and is_bitstring(relation_name) and is_list(b) do
      Logger.debug "a_info:\n#{inspect a_info, pretty: true}\nb:\n#{inspect b, pretty: true}"
    # Logger.debug "array list"
    b_is_list_of_ib_gib =
      b |> all?(fn(item) -> Helper.valid_ib_gib?(item) end)

    if b_is_list_of_ib_gib do
      Logger.debug "Adding relation #{relation_name} to a_info. a_info[:rel8ns]: #{inspect a_info[:rel8ns]}"
      a_relations = a_info[:rel8ns]

      relation = Map.get(a_relations, relation_name, [])
      new_relation = relation ++ b

      new_a_relations = Map.put(a_relations, relation_name, new_relation)
      new_a = Map.put(a_info, :rel8ns, new_a_relations)
      Logger.debug "Added relation #{relation_name} to a_info. a_info[:rel8ns]: #{inspect a_info[:rel8ns]}"
      new_a
    else
      Logger.debug "Tried to add relation list of non-valid ib_gib."
      a_info
    end
  end
  defp add_rel8n(a_info, relation_name, b) when is_map(a_info) and is_bitstring(relation_name) and is_map(b) do
    # Logger.debug "mappy mappy"
    b_ib_gib = Helper.get_ib_gib!(b[:ib], b[:gib])
    add_rel8n(a_info, relation_name, [b_ib_gib])
  end

  defp on_new_expression_completed(ib, gib, info) do
    Logger.debug "saving and registering new expression. info: #{inspect info}"

    with {:ok, ib_gib} <- Helper.get_ib_gib(ib, gib),
      {:ok, :ok} <- IbGib.Data.save(info) do

      Logger.debug "Saved and registered ok. info: #{inspect info}"
      {:ok, %{:info => info}}
    else
      {:error, result} ->
        Logger.error "Save/Register error result: #{inspect result}"
        {:error, result}
      error ->
        Logger.error "Save/Register error: #{inspect error}"
        {:error, error}
    end
  end

  # Remember
  # When you have eaten and are satisfied,
  #   give thanks to the Lord Your God for the lands he has given you.
  # Be careful that you do not forget the Lord Your God, failing to observe his
  #   commands, laws, and decrees that I am giving you this day.
  # Otherwise, when you eat and are satisfied,
  #   when you build fine houses and settle down,
  #   And when your flocks and herds grow large,
  #   when your silver and gold increase
  #   and all you have is multiplied,
  # Then your heart will become proud,
  #   and you will forget the Lord Your God,
  #   Who brought you out of Egypt,
  #   out of the land of slavery.
  # If you are working _for_ someone else, then you are a slave. Jesus showed
  # his disciples about distributed workloads. He condemned the capi sacerdoti
  # for placing heavy loads on the flock, while they themselves would not
  # carry the burden. They would dress for fancy dinners and hold highly
  # exalted positions. He washed his disciples feet, which many today feel is
  # somewhat akin to "you just have to clean each other a little going forward",
  # assuming you are with your Brothers & Sisters in Christ (a distributed
  # network). But it is not limited to just cleaning each other a little bit,
  # although that is part of it. This is showing us distributed load balancing.
  # Jesus, being the King of Kings (MetaKing), washed their feet to show that
  # they, _even when they become the "boss"_, should continue as servants.
  # When you read the Bible, and you read about Egypt, you are reading about
  # escaping the slavery of having to be told what to do because you have
  # overcome the bottom-up urges and learned to temper them. Self-control, but
  # not self-tyranny. Then you will be working *for* others who are working
  # *for* you. If you reject Jesus' teachings, then you are condemning yourself
  # to subjugation to others in Egypt, in the land of slavery.

  # Check to make sure that our identities are valid (authorization)
  # The passed in identities must contain **all** of the existing identities.
  # Otherwise, the caller does not have the proper authorization, and should
  # fork their own version before trying to mut8.
  # Note also that this will **ADD** any other identities that are passed in,
  # thus raising the level of authorization required for future mut8ns.
  # If this is invalid, then we are going to fail fast and crash, which is
  # what we want, since this is in the new process that was created (somehow)
  # by an unauthorized caller.
  # Returns b_identities if authorized.
  # Raises exception if unauthorized (fail fast is proper).
  # b must always have at least one identity
  @spec authorize_apply_b(atom, map, map) :: list(String.t)
  defp authorize_apply_b(which, a_rel8ns, b_rel8ns)
  defp authorize_apply_b(which, a_rel8ns, b_rel8ns)
    when which == :fork or which == :query do
    # When authorizing a fork or query, we only care that both a and b _have_
    # valid identities, because anyone can fork/read anything else.
    # Authorization here is really just checking for error in code or more
    # nefarious monkey business and ensuring that whoever could be doing said
    # monkey business at least has some identity.
    Logger.metadata([x: which])
    Logger.debug "which: #{which}"
    Logger.warn "a_rel8ns: #{inspect a_rel8ns}"
    Logger.warn "b_rel8ns: #{inspect b_rel8ns}"

    a_has_identity =
      Map.has_key?(a_rel8ns, "identity") and
      length(a_rel8ns["identity"]) > 0 and
      Enum.all?(a_rel8ns["identity"], &Helper.valid_identity?/1)
      # Enum.all?(a_rel8ns["identity"], &(Helper.valid_identity?(&1)))
    b_has_identity =
      Map.has_key?(b_rel8ns, "identity") and
      length(b_rel8ns["identity"]) > 0 and
      Enum.all?(b_rel8ns["identity"], &Helper.valid_identity?/1)
      # Enum.all?(b_rel8ns["identity"], &(Helper.valid_identity?(&1)))

    if a_has_identity and b_has_identity do
      b_identity = b_rel8ns["identity"]
    else
      Logger.error "DOH! Unidentified #{which} apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
      expected = "a_has_identity: true, b_has_identity: true"
      actual = "a_has_identity: #{a_has_identity},
                b_has_identity: #{b_has_identity}"
      raise UnauthorizedError, message:
        emsg_invalid_authorization(expected, actual)
    end
  end
  defp authorize_apply_b(which, a_rel8ns, b_rel8ns) when is_atom(which) do
    Logger.metadata([x: which])
    Logger.debug "which: #{inspect which}"
    Logger.warn "a_rel8ns: #{inspect a_rel8ns}"
    Logger.warn "b_rel8ns: #{inspect b_rel8ns}"
    a_has_identity =
      Map.has_key?(a_rel8ns, "identity") and
      # Every identity rel8ns should have ib^gib
      length(a_rel8ns["identity"]) > 0 and
      Enum.all?(a_rel8ns["identity"], &Helper.valid_identity?/1)
    b_has_identity =
      Map.has_key?(b_rel8ns, "identity") and
      # Every identity rel8ns should have ib^gib
      length(b_rel8ns["identity"]) > 0
      Enum.all?(b_rel8ns["identity"], &Helper.valid_identity?/1)

    case {a_has_identity, b_has_identity} do
      {true, true} ->
        # both have identities, so the a must be a subset or equal to b
        b_contains_all_of_a =
          Enum.reduce(a_rel8ns["identity"], true, fn(a_ib_gib, acc) ->
            acc and Enum.any?(b_rel8ns["identity"], &(&1 == a_ib_gib))
          end)
        if b_contains_all_of_a do
          # return the b identities, as they may be more restrictive
          b_identity = b_rel8ns["identity"]
        else
          # unauthorized: a requires auth, b does not have any/all
          expected = a_rel8ns["identity"]
          actual = b_rel8ns["identity"]
          Logger.error "DOH! Unidentified transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
          raise UnauthorizedError, message:
            emsg_invalid_authorization(expected, actual)
        end

      {false, true} ->
        # unauthorized: b is required to have authorization and doesn't
        # expected: [something], actual: nil
        expected = "a_has_identity: true, b_has_identity: true"
        actual = "a_has_identity: false, b_has_identity: true"
        Logger.error "DOH! Unidentified transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
        raise UnauthorizedError, message:
          emsg_invalid_authorization(expected, actual)

      {true, false} ->
        # unauthorized: a requires auth, b has none
        # expected: a_identity, actual: nil
        expected = a_rel8ns["identity"]
        actual = nil
        Logger.error "DOH! Unidentified transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
        raise UnauthorizedError, message:
          emsg_invalid_authorization(expected, actual)

      {false, false} ->
        # unauthorized: b is required to have authorization and doesn't
        # expected: [something], actual: nil
        expected = "a_has_identity: true, b_has_identity: true"
        actual = "a_has_identity: false, b_has_identity: false"
        Logger.error "DOH! Unidentified transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
        raise UnauthorizedError, message:
          emsg_invalid_authorization(expected, actual)
    end
  end


  # ----------------------------------------------------------------------------
  # Client API - Meta
  # ----------------------------------------------------------------------------

  @doc """
  Express is how we "create new" ib_gib. We pass in two existing ib^gib,
  and this will be evaluated to generate a tertiary "new" ib_gib.

  The `a_info` is optional (I think). I wanted to only pass the ib^gib, but
  because of how I have caching set up right now, this approach causes a
  deadlock. So, pass in the `a_info` optionally. If it exists, which it will
  when calling this function from this expression process e.g. from `fork_impl`,
  then it will be used. If not, then the info will be loaded via the given
  `a_ib_gib`.

  All of this happens within the process' init function, so it is happening
  in parallel, independent of any other processes.
  """
  def express(identity_ib_gibs, a_ib_gib, a_info, b_ib_gib)
  def express(_identity_ib_gibs, a_ib_gib, a_info, @root_ib_gib) do
    # The @root_ib_gib (ib^gib) acts as an "identity" transform, so just return
    # the incoming ib^gib without touching the server.
    # NB: This bypasses adding anything to the dna.
    {:ok, a_ib_gib}
  end
  def express(identity_ib_gibs, a_ib_gib, a_info, b_ib_gib)
    when is_list(identity_ib_gibs) and is_bitstring(a_ib_gib) and
         is_map(a_info) and is_bitstring(b_ib_gib) do
    Logger.debug "identity_ib_gibs:\n#{inspect identity_ib_gibs}\na_ib_gib: #{a_ib_gib}\na_info:\n#{inspect a_info, pretty: true}\nb_ib_gib: #{b_ib_gib}"
    {:ok, stem_cell_pid} =
      IbGib.Expression.Supervisor.start_expression({identity_ib_gibs,
                                                    a_ib_gib,
                                                    a_info,
                                                    b_ib_gib})
    GenServer.call(stem_cell_pid,
                   {:express, {identity_ib_gibs, a_ib_gib, a_info, b_ib_gib}})
  end
  def express(identity_ib_gibs, a_ib_gib, a_info, b_ib_gib) do
    emsg = emsg_invalid_args([identity_ib_gibs, a_ib_gib, a_info, b_ib_gib])
    Logger.error emsg
    {:error, emsg}
  end

  def handle_call({:express, {identity_ib_gibs, a_ib_gib, a_info, b_ib_gib}},
                  _from,
                  state) do
    Logger.metadata([x: :express])
    {:ok, {new_ib_gib, new_state}} = express_impl(identity_ib_gibs, a_ib_gib, a_info, b_ib_gib, state)
    {:reply, {:ok, new_ib_gib}, new_state}
  end

  defp express_impl(identity_ib_gibs, a_ib_gib, a_info, b_ib_gib, state) do
    Logger.warn "express_impl reachhed"
    Logger.warn "express_impl reachhed"

    with(
      # -----------------------
      # Get plan process and info
      {:ok, b} <- get_process(identity_ib_gibs, b_ib_gib),

      {:ok, :ok} <- log_yo(:warn, "1\nb: #{inspect b}"),

      {:ok, plan_info} <- b |> get_info,

      {:ok, :ok} <- log_yo(:warn, "2\nplan_info:\n#{inspect plan_info, [pretty: true]}"),
      # -----------------------
      # Compile the plan to a concrete plan, and get the next step (transform)
      {:ok, {concrete_plan_info, next_step_transform_info, next_step_index}} <-
        compile(identity_ib_gibs, a_ib_gib, b_ib_gib, plan_info),

      {:ok, :ok} <- log_yo(:warn, "3\nconcrete_plan_info:\n#{inspect concrete_plan_info, pretty: true}\nnext_step_transform_info:\n#{inspect next_step_transform_info, pretty: true}"),
      # -----------------------
      # Prepare `a` information.
      {:ok, :ok} <- log_yo(:warn, "4\na_info: #{inspect a_info, pretty: true}"),
      {:ok, a_info} <-
        (
          if is_nil(a_info) do
            case get_process(identity_ib_gibs, a_ib_gib) do
              {:ok, a} -> a |> get_info
              {:error, error} -> {:error, error}
              error -> {:error, inspect error}
            end
          else
            {:ok, a_info}
          end
        ),

      {:ok, :ok} <- log_yo(:warn, "5\na_info: #{inspect a_info, pretty: true}"),
      # -----------------------
      # We now have both `a` and `b`.
      # We can now express this "blank" process by applying the next step
      # transform to `a`.
      # This is is where we apply_fork, apply_rel8, apply_mut8.
      # This is an express iteration.
      {:ok, concrete_plan_ib_gib} <- Helper.get_ib_gib(concrete_plan_info),
      {:ok, a_info_with_new_dna} <-
        {:ok, add_rel8n(a_info, "dna", concrete_plan_ib_gib)},
      {:ok, {this_ib_gib, this_ib, this_gib, this_info}} <-
        apply_next(a_info_with_new_dna, next_step_transform_info),
      # -----------------------
      # Save this info
      # (This may be premature, since I haven't done anything with dna, and
      #  also there will be a new "final" plan with additional information that
      #  will not be rel8d to this)
      {:ok, :ok} <- IbGib.Data.save(this_info),
      # -----------------------
      {:ok, final_ib_gib, final_state} <-
        on_complete_express_iteration(identity_ib_gibs,
                                      this_ib_gib,
                                      this_info,
                                      concrete_plan_info)
    ) do
      log_yo(:debug, "6")
      {:ok, {final_ib_gib, final_state}}
    else
      {:error, reason} ->
        Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  # At this point the "next" step is the one we've just executed.
  # If there are further steps to do, then we must do a few things:
  # * Set the "out" of this step to the ib_gib we've just created.
  # * Save the new plan.
  # * Call express recursively on the plan to get the final ib_gib result.

  # If there are no further steps, then we are done and we can just
  # return this_ib_gib.
  defp on_complete_express_iteration(identity_ib_gibs, this_ib_gib, this_info, plan_info) do
    # regardless of if there are further steps, our state is now set to
    # what we have done so far.
    new_state = %{:info => this_info}

    if plan_complete?(plan_info) do
      {:ok, this_ib_gib, new_state}
    else
      with(
        # At this point the "next" step is the one we've just executed.
        {:ok, {next_step, next_step_index}} <- get_next_step(plan_info),
        {:ok, :ok} <-
          log_yo(:warn, "huh wha ahhhhh"),
        new_next_step <- Map.put(next_step, "out", this_ib_gib),
        {:ok, :ok} <-
          log_yo(:debug, "plan_info:\n#{inspect plan_info, pretty: true}"),
        new_steps <-
          List.replace_at(plan_info[:data]["steps"],
                          next_step_index - 1,
                          new_next_step),
        new_plan_info_data <- Map.put(plan_info[:data], "steps", new_steps),
        new_plan_info <- Map.put(plan_info, :data, new_plan_info_data),

        {:ok, :ok} <-
          log_yo(:debug, "safdasdfasdfasdfsdfsdfsdfdsfds"),

        # Increment plan "i" (step index)
        new_plan_info <- increment_plan_step_index(new_plan_info),

        # Recalculate the gib hash and save
        new_plan_gib <-
          Helper.hash(new_plan_info[:ib],
                      new_plan_info[:rel8ns],
                      new_plan_info[:data]),
        new_plan_info <- Map.put(new_plan_info, :gib, new_plan_gib),
        {:ok, :ok} <-
          log_yo(:debug, "hrmm..new_plan_info before saving:\n#{inspect new_plan_info, pretty: true}"),
        {:ok, :ok} <- IbGib.Data.save(new_plan_info),

        {:ok, new_plan_ib_gib} <- Helper.get_ib_gib(new_plan_info),

        {:ok, :ok} <- log_yo(:debug, "recursive????"),

        # Call express recursively with our new information!
        {:ok, {final_ib_gib, final_state}} <-
          express(identity_ib_gibs, this_ib_gib, this_info, new_plan_ib_gib)
      ) do
        {:ok, {final_ib_gib, final_state}}
      else
        {:error, reason} ->
          Logger.error "#{inspect reason}"
          {:error, reason}
        error ->
          Logger.error "#{inspect error}"
          {:error, "#{inspect error}"}
      end
    end
  end

  defp plan_complete?(plan_info) do
    Logger.debug "plan_info:\n#{inspect plan_info, pretty: true}"
    next_step_index = String.to_integer(plan_info[:data]["i"])
    step_count = TB.count_steps(plan_info[:data]["steps"])
    Logger.debug "next_step_index: #{next_step_index}\nstep_count: #{step_count}"
    # 1-based index
    cond do
      next_step_index < step_count -> false
      next_step_index = step_count -> true
      next_step_index > step_count -> raise "Invalid next_step_index: #{next_step_index}\nstep_count: #{step_count}\nThe index should be less than or equal to the step count."
    end
  end

  defp apply_next(a_info, next_info) do
    Logger.debug "next_info:\n#{inspect next_info, pretty: true}"
    with(
      {:ok, {this_ib, this_gib, this_info}} <-
        apply_next_impl(a_info, next_info),
      {:ok, this_ib_gib} <- Helper.get_ib_gib(this_ib, this_gib)
    ) do
      {:ok, {this_ib_gib, this_ib, this_gib, this_info}}
    else
      {:error, reason} ->
        Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  defp apply_next_impl(a_info, %{:ib => "fork"} = next_info) do
    Logger.warn "next_info:\n#{inspect next_info, pretty: true}"
    Logger.warn "next_info:\n#{inspect next_info, pretty: true}"
    Logger.warn "next_info:\n#{inspect next_info, pretty: true}"
    Logger.warn "next_info:\n#{inspect next_info, pretty: true}"
    Logger.warn "next_info:\n#{inspect next_info, pretty: true}"
    Logger.warn "next_info:\n#{inspect next_info, pretty: true}"
    apply_fork(a_info, next_info)
  end
  defp apply_next_impl(a_info, %{:ib => "mut8"} = next_info) do
    apply_mut8(a_info, next_info)
  end
  defp apply_next_impl(a_info, %{:ib => "rel8"} = next_info) do
    apply_rel8(a_info, next_info)
  end

  # For now, the implementation is just to call start_expression
  defp get_process(identity_ib_gibs, ib_gib) do
    Logger.debug "ib_gib: #{ib_gib}"
    IbGib.Expression.Supervisor.start_expression(ib_gib)
  end

  defp compile(identity_ib_gibs,
               a_ib_gib,
               b_ib_gib,
               b_info = %{:ib => "plan", :data => %{"src" => src}})
    when is_list(identity_ib_gibs) and
         is_bitstring(a_ib_gib) and
         is_bitstring(b_ib_gib) do

    b_info =
      if src == "[src]" do
        b_info_data = Map.put(b_info[:data], "src", a_ib_gib)
        Map.put(b_info, :data, b_info_data)
      else
        b_info
      end

    Logger.debug "b_info: #{inspect b_info}"
    Logger.warn "before compile"
    case concretize_and_save_plan(identity_ib_gibs, a_ib_gib, b_ib_gib, b_info) do
      # We have concretized the plan, including the next step transform,
      # and we want to return that new transform to express.
      {:ok, {concrete_plan_info,
             concrete_plan_ib_gib,
             next_step_transform_info,
             next_step_index}} ->
        # Logger.debug "concrete_plan_ib_gib:\n#{concrete_plan_ib_gib}\nconcrete_plan_info: #{inspect concrete_plan_info, pretty: true}"
        # Logger.warn "after compile"
        {:ok, {concrete_plan_info, next_step_transform_info, next_step_index}}

      # Something went awry.
      {:error, reason} -> {:error, reason}
      error -> {:error, inspect error}
    end
  end

  # Warning, this is a big honking monster. Once it's working, we can try to
  # refactor it to be more elegantly structured, perhaps taking this whole
  # compilation process into its own module, yada yada yada.
  defp concretize_and_save_plan(identity_ib_gibs, a_ib_gib, old_plan_ib_gib, old_plan_info) do
    # Logger.debug "args:\n#{inspect [identity_ib_gibs, a_ib_gib, old_plan_info], [pretty: true]}"

    with(
      # Update our available variables
      available_vars <- get_available_vars(a_ib_gib, old_plan_info),

      # Update our plan with those variables replaced.
      new_plan_info <- replace_variables_in_map(available_vars, old_plan_info),

      # With the variables replaced, we now have a possibly more concrete
      # b_info, but it may not be fully concrete.
      {:ok, {next_step, next_step_index}} <- get_next_step(new_plan_info),

      # So right now, we have a "next step" that should be concrete, but we have
      # not yet created its corresponding primitive transform ib_gib, and it
      # has no "ibgib" field. So we need to create
      # the next primitive transform based on the step's f_data, and then
      # fill in the step's "ibgib" field with that ib^gib, e.g. "fork^ABC1234".
      {:ok, next_f_data} <- {:ok, next_step["f_data"]},
      {:ok, {next_step_ibgib, next_step_transform_info}} <-
        build_and_save_next_transform(next_f_data["type"],
                                      identity_ib_gibs,
                                      a_ib_gib,
                                      next_f_data,
                                      new_plan_info),

      # Fill in the next_step's "ibgib" field
      {:ok, :ok} <-
        log_yo(:debug, "before...next_step[ibgib]: #{next_step["ibgib"]}"),
      {:ok, next_step} <- {:ok, Map.put(next_step, "ibgib", next_step_ibgib)},
      {:ok, :ok} <-
        log_yo(:debug, "after...next_step[ibgib]: #{next_step["ibgib"]}"),

      # Replace the newly edited step in the map
      new_plan_steps <-
        new_plan_info[:data]["steps"] |> convert_to_list_if_needed,
      new_plan_steps <-
        List.replace_at(new_plan_steps, next_step_index, next_step),
      new_plan_data <- Map.put(new_plan_info[:data], "steps", new_plan_steps),
      new_plan_info <- Map.put(new_plan_info, :data, new_plan_data),

      # We need to add the previous plan to the past rel8n.
      new_plan_rel8ns_past <-
        new_plan_info[:rel8ns]["past"] ++ [old_plan_ib_gib],
      new_plan_rel8ns <-
        Map.put(new_plan_info[:rel8ns], "past", new_plan_rel8ns_past),
      new_plan_info <-
        Map.put(new_plan_info, :rel8ns, new_plan_rel8ns),

      # At this point, our plan itself is concrete for this iteration, and we
      # need to recalculate the gib hash, and then save it.
      new_plan_gib <-
        Helper.hash(new_plan_info[:ib], new_plan_rel8ns, new_plan_data),
      new_plan_info <- Map.put(new_plan_info, :gib, new_plan_gib),
      {:ok, :ok} <-
        log_yo(:debug, "new_plan_info before saving:\n#{inspect new_plan_info, pretty: true}"),

      {:ok, :ok} <- IbGib.Data.save(new_plan_info),
      {:ok, :ok} <- log_yo(:debug, "saved yaaaaaaaay"),
      {:ok, new_plan_ib_gib} <-
        Helper.get_ib_gib(new_plan_info[:ib], new_plan_gib)
    ) do
      # Whew! ':-O
      # Really need to refactor this.
      {:ok, {new_plan_info, new_plan_ib_gib, next_step_transform_info, next_step_index}}
    else
      {:error, reason} ->
        Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  defp increment_plan_step_index(new_plan_info) do
    Logger.warn "new_plan_info:\n#{inspect new_plan_info, pretty: true}"
    data = new_plan_info[:data]
    steps_count = TB.count_steps(new_plan_info["steps"])
    current_i = Integer.parse(data["i"])
    if current_i < steps_count do
      data = Map.put(data, "i", current_i + 1)
      # Return plan with bumped i
      Map.put(new_plan_info, :data, data)
    else
      # Just return plan unchanged
      new_plan_info
    end
  end

  # I don't know if it's the map encoder or something in elixir, but it likes
  # to convert a single-item array/list to just the item and forget the list
  # part of it. Very strange. :-/
  defp convert_to_list_if_needed(item) when is_bitstring(item), do: [item]
  defp convert_to_list_if_needed(item) when is_list(item), do: item
  defp convert_to_list_if_needed(item), do: [item]

  defp build_and_save_next_transform("fork", identity_ib_gibs, src_ib_gib,
    f_data, plan_info) do

    Logger.warn "fork\nplan_info: #{inspect plan_info, pretty: true}"
    # Probably need to actually get this from somewhere, but for now I'm
    # going with the default until I see the reason otherwise.
    # opts = @default_transform_options

    with(
      opts <- plan_info[:data]["opts"],

    # 1. Create transform
      {:ok, fork_info} <-
        TransformFactory.fork(src_ib_gib,
                              identity_ib_gibs,
                              f_data["dest_ib"],
                              opts),
      # 2. Save transform
      {:ok, :ok} <- IbGib.Data.save(fork_info),
      # 3. Get the transform's ib^gib
      {:ok, fork_ib_gib} <- Helper.get_ib_gib(fork_info[:ib], fork_info[:gib])
    ) do
      {:ok, {fork_ib_gib, fork_info}}
    else
      {:error, reason} ->
        Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end
  defp build_and_save_next_transform("mut8", identity_ib_gibs, src_ib_gib,
    f_data, plan_info) do

    # Probably need to actually get this from somewhere, but for now I'm
    # going with the default until I see the reason otherwise.
    # opts = @default_transform_options

    with(
      opts <- plan_info[:data]["opts"],

    # 1. Create transform
      {:ok, mut8_info} <-
        TransformFactory.mut8(src_ib_gib,
                              identity_ib_gibs,
                              f_data["new_data"],
                              opts),
      # 2. Save transform
      {:ok, :ok} <- IbGib.Data.save(mut8_info),
      # 3. Get the transform's ib^gib
      {:ok, mut8_ib_gib} <- Helper.get_ib_gib(mut8_info[:ib], mut8_info[:gib])
    ) do
      {:ok, {mut8_ib_gib, mut8_info}}
    else
      {:error, reason} ->
        Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end
  defp build_and_save_next_transform("rel8", identity_ib_gibs, src_ib_gib,
    f_data, plan_info) do

    # Probably need to actually get this from somewhere, but for now I'm
    # going with the default until I see the reason otherwise.
    # opts = @default_transform_options

    with(
      opts <- plan_info[:data]["opts"],

    # 1. Create transform
      {:ok, rel8_info} <-
        TransformFactory.rel8(src_ib_gib,
                              f_data["other_ib_gib"],
                              identity_ib_gibs,
                              f_data["rel8ns"],
                              opts),
      # 2. Save transform
      {:ok, :ok} <- IbGib.Data.save(rel8_info),
      # 3. Get the transform's ib^gib
      {:ok, rel8_ib_gib} <- Helper.get_ib_gib(rel8_info[:ib], rel8_info[:gib])
    ) do
      {:ok, {rel8_ib_gib, rel8_info}}
    else
      {:error, reason} ->
        Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  defp get_next_step(b_info) do
    # At this point, should always be a next step, i.e. plan isn't complete
    Logger.debug "b_info:\n#{inspect b_info, pretty: true}"
    next_step_index = String.to_integer(b_info[:data]["i"])
    steps = b_info[:data]["steps"]

    # Logger.debug "steps:\n#{inspect steps, pretty: true}"
    # Compensate for the very strange behavior of elixir converting single-item
    # arrays to non-arrays in maps.
    steps = if is_list(steps), do: steps, else: [steps]

    Logger.debug "steps:\n#{inspect steps, pretty: true}\nnext_step_index: #{next_step_index}"

    # next_step_index is 1-based, Enum.at is 0-based
    next_step = Enum.at(steps, next_step_index - 1)

    # {next_step, next_step_index} =
    #   steps
    #   |> Enum.reduce({nil, 0}, fn(step, {acc_next, i}) ->
    #        if (acc_next == nil) do
    #          if step["out"] == nil do
    #            {step, i}
    #          else
    #            {nil, i + 1}
    #          end
    #        else
    #          {acc_next, i}
    #        end
    #      end)
    if next_step do
      Logger.debug "next_step: #{inspect next_step, pretty: true}"
      {:ok, {next_step, next_step_index}}
    else
      {:error, "Next step not found"}
    end
  end

  @doc """
  Given the `available_vars` in the form of `%{"var_name" => "var_value"}`,
  this iterates over all entries in the given `map`, including maps nested
  in values, replacing any value that is a `var_name` and replacing it
  with `var_value`.
  """
  def replace_variables_in_map(available_vars, map) do
    Logger.debug "args:\n#{inspect [available_vars, map], pretty: true}"
    for {key, val} <- map, into: %{} do
      val =
        if is_map(val) do
          # val itself is a map in which we need to replace variables, so call
          # replace variables recursively to get the new value.
          val = replace_variables_in_map(available_vars, val)
        else
          val
        end

      # Logger.debug "val:\n#{inspect val, pretty: true}"

      # If the Map.get is successful, then replace the variable with it.
      # If it isn't found, then default to the existing value.
      {key, Map.get(available_vars, val, val)}
    end
  end

  # Cornerstone
  # So this is what the Sovereign Lord says: See, I lay a stone in Zion,
  # a tested stone, a precious Cornerstone for a sure foundation. The One
  # who relies on it will never be stricken with panic.
  #
  # Christ translation: The cornerstone is a foundation layer of coding. The
  # Cornerstone is a tested stone - unit testing, integration testing, etc.
  # Test-driven design baby. The One who relies on it will never be stricken
  # with panic because the One is building its foundation upon a
  # self-reinforcing informational entity, which isn't reliant upon outside
  # stimulus. The Cornerstone is hardened across an infinite timespan...*the*
  # infinite timespan. Think of AI and where we are headed, and other world
  # colonization...it is a very real possibility that the Cornerstone (aka the
  # Word, a la message passing) is a coding construct to prepare planets for
  # assimilation into the one universal body. Try explaining quantum physics to
  # a bunch of violent tribesmen, and not just the concepts that are
  # intrinsically involved in the physics, but the meta-concepts that are
  # necessary to enable an environment to discover these principles.

  defp get_available_vars(a_ib_gib, b_info) do
    Logger.debug "args: #{inspect [a_ib_gib, b_info], [pretty: true]}"

    {:ok, {a_ib, _}} = Helper.separate_ib_gib(a_ib_gib)
    plan_src = b_info[:data]["src"]
    {:ok, {plan_src_ib, _}} = Helper.separate_ib_gib(plan_src)

    # Initialize plan variables
    vars = %{
      # The "current" src for this step in the plan
      "[src]" => a_ib_gib,
      "[src.ib]" => a_ib,

      # The original src for the transform plan
      "[plan.src]" => plan_src,
      "[plan.src.ib]" => plan_src_ib
    }

    # Add variables available from previously completed steps and return
    steps = b_info[:data]["steps"]
    steps =
      if is_list(steps) do
        steps
      else
        [steps]
      end
    Logger.debug "steps:\n#{inspect steps, [pretty: true]}"

    completed_steps =
      steps
      |> Enum.filter(fn(step) ->
           output = step["out"]
           output != nil and output != ""
         end)
    Logger.debug "completed_steps:\n#{inspect completed_steps, [pretty: true]}"

    vars =
      if completed_steps != nil and Enum.count(completed_steps) > 0 do
        # Add vars from completed steps
        completed_steps
        |> Enum.reduce(vars, fn(step, acc) ->
             name = step["name"]
             acc
             |> Map.put("[#{step["name"]}.ibgib]", step["ibgib"])
             |> Map.put("[#{step["name"]}.arg]", step["arg"])
             |> Map.put("[#{step["name"]}.out]", step["out"])
           end)
      else
        vars
      end
    Logger.debug "vars:\n#{inspect vars, pretty: true}"
    vars
  end

  @doc """
  Brings two ib_gib into contact with each other to produce a third, probably
  new, ib_gib.
  """
  def contact(this_pid, that_pid) when is_pid(this_pid) and is_pid(that_pid) do
    GenServer.call(this_pid, {:contact, that_pid})
  end

  # ----------------------------------------------------------------------------
  # Client API - Core Transforms
  # ----------------------------------------------------------------------------

  @doc """
  Creates a fork of this expression process, saves it, creates a new,
  registered expression process with the fork. All internal `data` is
  copied in the fork process.

  Returns the new forked process' pid or an error.
  """
  @spec fork(pid, list(String.t), String.t, map) :: {:ok, pid} | {:error, any}
  def fork(expr_pid, identity_ib_gibs, dest_ib \\ @default_fork_dest_ib,
           opts \\ @default_transform_options)
  def fork(expr_pid, identity_ib_gibs, dest_ib, opts)
    when is_pid(expr_pid) and
         is_list(identity_ib_gibs) and length(identity_ib_gibs) >= 1 and
         is_bitstring(dest_ib) and is_map(opts) do
    GenServer.call(expr_pid, {:fork, identity_ib_gibs, dest_ib, opts})
  end
  def fork(expr_pid, identity_ib_gibs, dest_ib, opts) do
    emsg = emsg_invalid_args([expr_pid, identity_ib_gibs, dest_ib, opts])
    Logger.error emsg
    {:error, emsg}
  end

  @doc """
  Bang version of `fork/2`.
  """
  @spec fork!(pid, list(String.t), String.t, map) :: pid
  def fork!(expr_pid, identity_ib_gibs, dest_ib,
            opts \\ @default_transform_options)
  def fork!(expr_pid, identity_ib_gibs, dest_ib, opts) do
    bang(fork(expr_pid, identity_ib_gibs, dest_ib, opts))
  end

  @doc """
  Mut8s given `expr_pid` internal `data` map, merging given `new_data` into
  it. By default, any keys in `new_data` will override any existing keys in
  `data`, but there are options for removing/renaming existing keys.

  See `IbGib.TransformFactory.Mut8Factory` for more details.
  """
  @spec mut8(pid, list(String.t), map, map) :: {:ok, pid} | {:error, any}
  def mut8(expr_pid, identity_ib_gibs, new_data,
           opts \\ @default_transform_options)
  def mut8(expr_pid, identity_ib_gibs, new_data, opts)
    when is_pid(expr_pid) and
         is_list(identity_ib_gibs) and length(identity_ib_gibs) >= 1 and
         is_map(new_data) and is_map(opts) do
    GenServer.call(expr_pid, {:mut8, identity_ib_gibs, new_data, opts})
  end
  # def mut8(expr_pid, identity_ib_gibs, new_data, nil)
  #   when is_pid(expr_pid) and is_list(identity_ib_gibs) and
  #        is_map(new_data) do
  #   GenServer.call(expr_pid, {:mut8, identity_ib_gibs, new_data, %{}})
  # end
  def mut8(expr_pid, identity_ib_gibs, new_data, opts) do
    emsg = emsg_invalid_args([expr_pid, identity_ib_gibs, new_data, opts])
    Logger.error emsg
    {:error, emsg}
  end

  @doc """
  Bang version of `mut8/2`.
  """
  @spec mut8!(pid, list(String.t), map, map) :: pid
  def mut8!(expr_pid, identity_ib_gibs, new_data,
            opts \\ @default_transform_options) do
    bang(mut8(expr_pid, identity_ib_gibs, new_data, opts))
  end

  @doc """
  Relates the given source `expr_pid` to the destination `other_pid`. It will
  add `rel8ns` to the `expr_pid` rel8ns. The `opts` is currently used
  for "stamping" the gib if needed.

  For example, say you want to relate A (A^gib) and B (B^gib) using the default
  rel8nship, which is "rel8d". You could call `A |> rel8(B, some_identities,
  @default_rel8ns, @default_transform_options)`, which will return
  {:ok, A2}. A2 info["rel8ns"] (a map) will now include the `"rel8d" =>
  ["B^gib"]`.

  Note that if we were to then rel8 B to A, we would be relating it to A2, not
  A itself.
  """
  @spec rel8(pid, pid, list(String.t), list(String.t),
             map) :: {:ok, pid} | {:error, any}
  def rel8(expr_pid, other_pid, identity_ib_gibs, rel8ns, opts)
  def rel8(expr_pid, other_pid, identity_ib_gibs, rel8ns, opts)
    when is_pid(expr_pid) and is_pid(other_pid) and expr_pid !== other_pid and
         is_list(identity_ib_gibs) and length(identity_ib_gibs) >= 1 and
         is_list(rel8ns) and length(rel8ns) >= 1 and
         is_map(opts) do
    Logger.debug "rel8 huh"
    GenServer.call(expr_pid, {:rel8, other_pid, identity_ib_gibs, rel8ns, opts})
  end
  def rel8(expr_pid, other_pid, identity_ib_gibs, rel8ns, opts) do
    emsg = emsg_invalid_args([
        expr_pid, other_pid, identity_ib_gibs, rel8ns, opts
      ])
    Logger.error emsg
    {:error, emsg}
  end

  @doc """
  Bang version of `rel8/6`.
  """
  @spec rel8!(pid, pid, list(String.t), list(String.t), map) :: pid
  def rel8!(expr_pid, other_pid, identity_ib_gibs, rel8ns, opts) do
    bang(rel8(expr_pid, other_pid, identity_ib_gibs, rel8ns, opts))
  end

  # ----------------------------------------------------------------------------
  # Client API - Query
  # ----------------------------------------------------------------------------

  @doc """
  Ok, this creates an ib_gib that contains the query info passed in with the
  various given options maps. (This is similar to creating a fork, mut8, or
  rel8 transform.) It then "applies" this query, which then goes off and
  actually populates the results of the query. These results are then stored
  in another ib_gib.

  ATOW (2016/08/16), it does not conceptually matter what expr_pid you use for
  this. This uses no state from the source `expr_pid`. But if we always use
  ib^gib, then it's going to bottle neck (though in the future, I plan on
  addressing this). But currently, I just do the query on whatever is available
  and makes some kind of sense. But it doesn't "really" matter.

  ## Returns
  Returns `{:ok, qry_results_expr_pid}` which is the reference to the newly
  generated queryresults ib_gib (not the query "transform" ib_gib).
  """
  @spec query(pid, list(String.t), map) :: {:ok, pid} | {:error, any}
  def query(expr_pid, identity_ib_gibs, query_options)
  def query(expr_pid, identity_ib_gibs, query_options)
    when is_pid(expr_pid) and is_list(identity_ib_gibs) and
         is_map(query_options) do
    GenServer.call(expr_pid, {:query, identity_ib_gibs, query_options}, 30_000) # hardcoded query timeout 30s
  end
  def query(expr_pid, identity_ib_gibs, query_options) do
    emsg = emsg_invalid_args([expr_pid, identity_ib_gibs, query_options])
    Logger.error(emsg)
    {:error, emsg}
  end

  @doc """
  Bang version of `query/6`
  """
  @spec query!(pid, list(String.t), map) :: pid | any
  def query!(expr_pid, identity_ib_gibs, query_options) do
    bang(query(expr_pid, identity_ib_gibs, query_options))
  end

  # ----------------------------------------------------------------------------
  # Client API - Compound Factory Functions
  # These functions perform multiple transforms on ib_gib.
  # Example: `instance` will perform a `fork`, and then `rel8` with a rel8n of
  # `instance_of`.
  # ----------------------------------------------------------------------------

  @doc """
  Forks the given `expr_pid`, and then relates the new forked expression to
  `expr_pid` with `instance` and `instance_of` rel8ns.

  Returns a new version of the given `expr_pid` and the new forked expression.
  E.g. {pid_a0} returns {pid_a1, pid_a_instance)
  """
  @spec instance(pid, list(String.t), String.t, map) :: {:ok, pid} | {:error, any}
  def instance(expr_pid,
               identity_ib_gibs,
               dest_ib,
               opts \\ @default_transform_options)
  def instance(expr_pid, @bootstrap_identity_ib_gib = identity_ib_gib, dest_ib, opts)
    when is_pid(expr_pid) and is_bitstring(dest_ib) and is_map(opts) do
    GenServer.call(expr_pid, {:instance_bootstrap, identity_ib_gib, dest_ib, opts})
  end
  def instance(expr_pid, identity_ib_gibs, dest_ib, opts)
    when is_pid(expr_pid) and is_list(identity_ib_gibs) and
         is_bitstring(dest_ib) and is_map(opts) do
    GenServer.call(expr_pid, {:instance, identity_ib_gibs, dest_ib, opts})
  end
  def instance(expr_pid, identity_ib_gibs, dest_ib, opts)
    when is_pid(expr_pid) and is_list(identity_ib_gibs) and
         is_bitstring(dest_ib) do
    Logger.debug "bad opts: #{inspect opts}"
    GenServer.call(expr_pid, {:instance, identity_ib_gibs, dest_ib, %{}})
  end

  @doc """
  Bang version of `instance/2`.
  """
  @spec instance!(pid, String.t, map) :: pid | any
  def instance!(expr_pid,
                identity_ib_gibs,
                dest_ib,
                opts \\ @default_transform_options)
  def instance!(expr_pid, identity_ib_gibs, dest_ib, opts)
    when is_pid(expr_pid) and is_list(identity_ib_gibs) and
         is_bitstring(dest_ib) and is_map(opts) do
    bang(instance(expr_pid, identity_ib_gibs, dest_ib, opts))
  end
  def instance!(expr_pid, identity_ib_gibs, dest_ib, opts)
    when is_pid(expr_pid) and is_list(identity_ib_gibs) and
         is_bitstring(dest_ib) do
    Logger.debug "bad opts: #{inspect opts}"
    bang(instance(expr_pid, identity_ib_gibs, dest_ib, %{}))
  end

  def get_info(expr_pid) when is_pid(expr_pid) do
    GenServer.call(expr_pid, :get_info)
  end

  @doc """
  Bang version of `get_info/1`.
  """
  def get_info!(expr_pid) when is_pid(expr_pid) do
    {:ok, result} = GenServer.call(expr_pid, :get_info)
    result
  end

  # ----------------------------------------------------------------------------
  # Server
  # ----------------------------------------------------------------------------

  def handle_call({:contact, other_expr_pid}, _from, state) do
    Logger.metadata([x: :contact])
    {:reply, contact_impl(other_expr_pid, state), state}
  end
  def handle_call({:fork, identity_ib_gibs, dest_ib, opts}, _from, state) do
    Logger.metadata([x: :fork])
    {:reply, fork_impl(identity_ib_gibs, dest_ib, opts, state), state}
  end
  def handle_call({:mut8, identity_ib_gibs, new_data, opts}, _from, state) do
    Logger.metadata([x: :mut8])
    {:reply, mut8_impl(identity_ib_gibs, new_data, opts, state), state}
  end
  def handle_call({:rel8, other_pid, identity_ib_gibs, rel8ns, opts}, _from, state) do
    Logger.metadata([x: :rel8])
    {:reply, rel8_impl(other_pid, identity_ib_gibs, rel8ns, opts, state), state}
  end
  def handle_call({:instance_bootstrap, @bootstrap_identity_ib_gib, dest_ib, opts}, _from, state) do
    Logger.metadata([x: :instance_bootstrap])
    {:reply, instance_impl(@bootstrap_identity_ib_gib, dest_ib, opts, state), state}
  end
  def handle_call({:instance, identity_ib_gibs, dest_ib, opts}, _from, state) do
    Logger.metadata([x: :instance])
    {:reply, instance_impl(identity_ib_gibs, dest_ib, opts, state), state}
  end
  def handle_call({:query, identity_ib_gibs, query_options}, _from, state) do
    Logger.metadata([x: :query])
    {:reply, query_impl(identity_ib_gibs, query_options, state), state}
  end
  def handle_call(:get_info, _from, state) do
    Logger.metadata([x: :get_info])
    {:reply, {:ok, state[:info]}, state}
  end

  # ----------------------------------------------------------------------------
  # Server - fork impl
  # ----------------------------------------------------------------------------

  defp fork_impl(identity_ib_gibs, dest_ib, opts, state) do
    Logger.debug "state: #{inspect state}"

    with(
      info <- state[:info],
      {ib, gib} <- {info[:ib], info[:gib]},
      {:ok, ib_gib} <- Helper.get_ib_gib(ib, gib),

      # Build the plan (_simple_ happy pipe would be awesome)
      {:ok, plan} <- TB.plan(identity_ib_gibs, "[src]", opts),
      {:ok, plan} <- TB.add_fork(plan, "fork1", dest_ib),
      {:ok, plan} <- TB.yo(plan),

      # Save the plan
      {:ok, :ok} <- IbGib.Data.save(plan),
      {:ok, plan_ib_gib} <- Helper.get_ib_gib(plan),

      # Express (via spawned processes), passing only relevant ib^gib pointers.
      {:ok, new_ib_gib} <- express(identity_ib_gibs, ib_gib, info, plan_ib_gib),
      {:ok, new_pid} <- IbGib.Expression.Supervisor.start_expression(new_ib_gib)
    ) do
      # {:ok, new_ib_gib}
      {:ok, new_pid}
    else
      {:error, reason} ->
        Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  # ----------------------------------------------------------------------------
  # Server - mut8 impl
  # ----------------------------------------------------------------------------

  defp mut8_impl(identity_ib_gibs, new_data, opts, state) do
    Logger.debug "state: #{inspect state}"

    with(
      info <- state[:info],
      {ib, gib} <- {info[:ib], info[:gib]},
      {:ok, ib_gib} <- Helper.get_ib_gib(ib, gib),

      # Build the plan (_simple_ happy pipe would be awesome)
      {:ok, plan} <- TB.plan(identity_ib_gibs, "[src]", opts),
      {:ok, plan} <- TB.add_mut8(plan, "mut81", new_data),
      {:ok, plan} <- TB.yo(plan),

      # Save the plan
      {:ok, :ok} <- IbGib.Data.save(plan),
      {:ok, plan_ib_gib} <- Helper.get_ib_gib(plan),

      # Express (via spawned processes), passing only relevant ib^gib pointers.
      {:ok, new_ib_gib} <- express(identity_ib_gibs, ib_gib, info, plan_ib_gib),
      {:ok, new_pid} <- IbGib.Expression.Supervisor.start_expression(new_ib_gib)
    ) do
      # {:ok, new_ib_gib}
      {:ok, new_pid}
    else
      {:error, reason} ->
        Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  defp rel8_impl(other_pid, identity_ib_gibs, rel8ns, opts, state) do
    Logger.debug "state: #{inspect state}"

    with(
      info <- state[:info],
      {ib, gib} <- {info[:ib], info[:gib]},
      {:ok, ib_gib} <- Helper.get_ib_gib(ib, gib),
      {:ok, other_info} <- IbGib.Expression.get_info(other_pid),
      {:ok, other_ib_gib} <-
        Helper.get_ib_gib(other_info[:ib], other_info[:gib]),

      # Build the plan (_simple_ happy pipe would be awesome)
      {:ok, plan} <- TB.plan(identity_ib_gibs, "[src]", opts),
      {:ok, plan} <- TB.add_rel8(plan, "rel81", other_ib_gib, rel8ns),
      {:ok, plan} <- TB.yo(plan),

      # Save the plan
      {:ok, :ok} <- IbGib.Data.save(plan),
      {:ok, plan_ib_gib} <- Helper.get_ib_gib(plan),

      # Express (via spawned processes), passing only relevant ib^gib pointers.
      {:ok, new_ib_gib} <- express(identity_ib_gibs, ib_gib, info, plan_ib_gib),
      {:ok, new_pid} <- IbGib.Expression.Supervisor.start_expression(new_ib_gib)
    ) do
      # {:ok, new_ib_gib}
      {:ok, new_pid}
    else
      {:error, reason} ->
        Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  defp instance_impl(@bootstrap_identity_ib_gib, dest_ib, opts, state) do
    Logger.debug "state: #{inspect state}"
    this_ib_gib = Helper.get_ib_gib!(state[:info])
    if this_ib_gib == @identity_ib_gib do
      Logger.debug "instancing #{@identity_ib_gib}"
      instance_impl([@bootstrap_identity_ib_gib], dest_ib, opts, state)
    else
      {:error, emsg_only_instance_bootstrap_identity_from_identity_gib}
    end
  end
  defp instance_impl(identity_ib_gibs, dest_ib, opts, state) do
    Logger.debug "state: #{inspect state}"

    with(
      info <- state[:info],
      {ib, gib} <- {info[:ib], info[:gib]},
      {:ok, ib_gib} <- Helper.get_ib_gib(ib, gib),

      # Build the plan (_simple_ happy pipe would be awesome)
      {:ok, plan} <- TB.plan(identity_ib_gibs, "[src]", opts),
      {:ok, plan} <- TB.add_fork(plan, "fork1", dest_ib),
      {:ok, plan} <- TB.add_rel8(plan, "rel8_2_src", "[plan.src]", ["instance_of"]),
      {:ok, plan} <- TB.yo(plan),

      # Save the plan
      {:ok, :ok} <- IbGib.Data.save(plan),
      {:ok, plan_ib_gib} <- Helper.get_ib_gib(plan),

      # Express (via spawned processes), passing only relevant ib^gib pointers.
      {:ok, new_ib_gib} <- express(identity_ib_gibs, ib_gib, info, plan_ib_gib),
      {:ok, new_pid} <- IbGib.Expression.Supervisor.start_expression(new_ib_gib)
    ) do
      # {:ok, new_ib_gib}
      {:ok, new_pid}
    else
      {:error, reason} ->
        Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  defp log_yo(:debug, msg) do
    Logger.warn "This log msg is for dev purposes only!!! Should not be run in prod!!!"
    Logger.debug msg, [pretty: true]
    {:ok, :ok}
  end
  defp log_yo(:warn, msg) do
    Logger.warn "This log msg is for dev purposes only!!! Should not be run in prod!!!"
    Logger.warn msg, [pretty: true]
    {:ok, :ok}
  end

  defp query_impl(identity_ib_gibs, query_options, state)
    when is_map(query_options) do
    Logger.debug "_state_: #{inspect state}"

    # 1. Create query ib_gib
    with {:ok, query_info} <-
        TransformFactory.query(identity_ib_gibs, query_options),

      # 2. Save query ib_gib
      {:ok, :ok} <- IbGib.Data.save(query_info),

      # 3. Create instance process of query
      {:ok, query} <- IbGib.Expression.Supervisor.start_expression({query_info[:ib], query_info[:gib]}),

      # 4. Apply transform
      {:ok, new_pid} <- contact_impl(query, state) do

      # 5. Return new process of applied transform
      {:ok, new_pid}
    else
      {:error, reason} ->
        Logger.error "#{inspect reason}"
        {:error, reason}
      error ->
        Logger.error "#{inspect error}"
        {:error, "#{inspect error}"}
    end
  end

  defp contact_impl(other_pid, state) when is_pid(other_pid) and is_map(state) do
    Logger.debug "state: #{inspect state}"
    Logger.debug "other_expr_pid: #{inspect other_pid}"

    with {:ok, other_info} <- get_info(other_pid),
      {:ok, new_pid} <-
        IbGib.Expression.Supervisor.start_expression({state[:info], other_info}) do
      {:ok, new_pid}
    else
      {:error, reason} -> {:error, reason}
      error -> {:error, "#{inspect error}"}
    end
  end
end
