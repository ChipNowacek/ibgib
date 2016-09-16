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
  alias IbGib.Errors.UnauthorizedError
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

  # ----------------------------------------------------------------------------
  # Inits
  # ----------------------------------------------------------------------------
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
      # if ib === "ib" and gib === "gib" do
      # else
      #   Logger.debug "initializing ib_gib expression by loading data. ib: #{ib}, gib: #{gib}"
      #   IbGib.Data.load!(ib, gib)
      # end
    register_result = IbGib.Expression.Registry.register(Helper.get_ib_gib!(ib, gib), self)
    if register_result == :ok do
      {:ok, %{:info => info}}
    else
      Logger.error "Register expression error: #{inspect register_result}"
      {:error, register_result}
    end
  end
  def init({:apply, {a, b}}) when is_map(a) and is_map(b) do
    Logger.metadata([x: :apply])
    cond do
      b[:ib] === "fork" and b[:gib] !== "gib" ->
        apply_fork(a, b)
      b[:ib] === "mut8" and b[:gib] !== "gib" ->
        apply_mut8(a, b)
      b[:ib] === "rel8" and b[:gib] !== "gib" ->
        apply_rel8(a, b)
      b[:ib] === "query" and b[:gib] !== "gib" ->
        apply_query(a, b)
      true ->
        err_msg = "unknown combination: a: #{inspect a}, b: #{inspect b}"
        Logger.error err_msg
        {:error, err_msg}
    end
  end

  defp init_default(:root) do
    %{
      :ib => "ib",
      :gib => "gib",
      :rel8ns => %{
        "dna" => @default_dna,
        "ancestor" => @default_ancestor,
        "past" => @default_past
        },
      :data => %{}
    }
  end
  defp init_default(:fork), do: get_default("fork")
  defp init_default(:mut8), do: get_default("mut8")
  defp init_default(:rel8), do: get_default("rel8")
  defp init_default(:query), do: get_default("query")

  defp get_default(ib_string) when is_bitstring(ib_string) do
    Logger.debug "initializing ib_gib #{ib_string} expression."
    %{
      :ib => ib_string,
      :gib => "gib",
      :rel8ns => %{
        "dna" => @default_dna,
        "ancestor" => @default_ancestor,
        "past" => @default_past
        },
      :data => %{}
    }
  end

  # ----------------------------------------------------------------------------
  # Apply Functions
  # We are within an init of a new process, and we are applying the given `b`
  # ib_gib info map (transform/query) to a given `a` "starting point" ib_gib
  # info map. See moduledoc for more details.
  # ----------------------------------------------------------------------------
  defp apply_fork(a, b) do
    # We are applying a fork transform.
    Logger.debug "applying fork b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    Logger.debug "a[:rel8ns]: #{inspect a[:rel8ns]}"
    fork_data = b[:data]
    # b_ib_gib = Helper.get_ib_gib!(b[:ib], b[:gib])

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
    this_info = this_info |> add_relation("dna", b)
    Logger.debug "fork_data[\"src_ib_gib\"]: #{fork_data["src_ib_gib"]}"


    this_info =
      if a_ancestor == [@root_ib_gib] and a[:ib] == "ib" and a[:gib] == "gib" do
        # Don't add a duplicate ib^gib ancestor
        this_info
      else
        # Add fork src as ancestor
        this_info |> add_relation("ancestor", fork_data["src_ib_gib"])
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

    on_new_expression_completed(this_ib, this_gib, this_info)
  end

  defp apply_mut8(a, b) do
    b_identities = authorize_apply_b(a[:rel8ns], b[:rel8ns])

    # We are applying a mut8 transform.
    Logger.debug "applying mut8 b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    Logger.debug "a[:rel8ns]: #{inspect a[:rel8ns]}"

    # We're going to borrow `a` as our own info for the new thing. We're just
    # going to change its `gib`, and `relations`, and its `data` since it's
    # a mut8 transform.

    # the ib stays the same
    ib = a[:ib]
    original_gib = a[:gib]
    original_ib_gib = Helper.get_ib_gib!(ib, original_gib)
    Logger.debug "retaining ib. a[:ib]...: #{ib}"

    # Passed authorization.
    # I do not call add_relation for this, because I want it to overwrite.
    a_rel8ns = Map.put(a[:rel8ns], "identity", b_identities)
    a = Map.put(a, :rel8ns, a_rel8ns)

    # We add the mut8 itself to the `relations`.
    a =
      a
      |> add_relation("past", original_ib_gib)
      |> add_relation("dna", b)

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

    on_new_expression_completed(ib, this_gib, a)
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

    # We add the rel8 transform to the dna.
    a = a |> add_relation("dna", b)

    # We need to know if we are source or destination of this rel8n.
    src_ib_gib = b[:data]["src_ib_gib"]
    dest_ib_gib = b[:data]["dest_ib_gib"]

    # Retaining ib because is a rel8 transform
    a_ib_gib = Helper.get_ib_gib!(a[:ib], a[:gib])

    {new_relations, other_ib_gib} =
      if a_ib_gib == src_ib_gib do
        {b[:data]["src_rel8ns"], dest_ib_gib}
      else
        {b[:data]["dest_rel8ns"], src_ib_gib}
      end
    Logger.debug "new_relations: #{inspect new_relations}, other_ib_gib: #{other_ib_gib}"
    new_a_relations =
      Enum.reduce(new_relations, a[:rel8ns], fn(x, acc) ->
        if Map.has_key?(acc, x) and !Enum.member?(acc[x], other_ib_gib) do
          # We already have the key, so append it to the end of the list
          Map.put(acc, x, acc[x] ++ [other_ib_gib])
        else
          Map.put_new(acc, x, [other_ib_gib])
        end
      end)
    a = Map.put(a, :rel8ns, new_a_relations)
    Logger.debug "new a: #{inspect a}"

    # Now we calculate the new hash and set it to `:gib`.
    ib = a[:ib]
    this_gib = Helper.hash(ib, a[:rel8ns], a[:data])
    this_gib =
      if Helper.gib_stamped?(b[:gib]) do
        Helper.stamp_gib!(this_gib)
      else
        this_gib
      end
    Logger.debug "this_gib: #{this_gib}"
    a = Map.put(a, :gib, this_gib)

    Logger.debug "a[:gib] set to gib: #{a[:gib]}"

    on_new_expression_completed(ib, this_gib, a)
  end

  defp apply_query(a, b) do
    Logger.debug "a: #{inspect a}\nb: #{inspect b}"
    b_identities = authorize_apply_b(a[:rel8ns], b[:rel8ns])

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
      "ancestor" => @default_ancestor ++ ["query_result#{delim}gib"],
      "past" => @default_past,
      "identity" => b_identities
    }
    this_info =
      this_info
      |> Map.put(:ib, this_ib)
      |> Map.put(:data, this_data)
      |> Map.put(:rel8ns, this_rel8ns)
      |> add_relation("dna", b)
      |> add_relation("query", b)
      |> add_relation(
          "result",
          result |> reduce(["ib#{@delim}gib"], fn(ib_gib_model, acc) ->
            acc ++ [Helper.get_ib_gib!(ib_gib_model.ib, ib_gib_model.gib)]
          end))

    # who = IbGib.QueryOptionsFactory.get_identities(query_options)
    #
    # this_info =
    #   if who != nil do
    #     this_info
    #     |> add_relation("identity", who)
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
  #     ...> add_relation(a_info, relation_name, b)
  #     %{ib: "some ib", gib: "some_gib", rel8ns: %{"ancestor" => ["ib^gib", "ib b^gib_b"]}}
  defp add_relation(a_info, relation_name, b)
  defp add_relation(a_info, relation_name, b) when is_map(a_info) and is_bitstring(relation_name) and is_bitstring(b) do
    # Logger.debug "bitstring yo"
    add_relation(a_info, relation_name, [b])
  end
  defp add_relation(a_info, relation_name, b) when is_map(a_info) and is_bitstring(relation_name) and is_list(b) do
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
  defp add_relation(a_info, relation_name, b) when is_map(a_info) and is_bitstring(relation_name) and is_map(b) do
    # Logger.debug "mappy mappy"
    b_ib_gib = Helper.get_ib_gib!(b[:ib], b[:gib])
    add_relation(a_info, relation_name, [b_ib_gib])
  end

  defp on_new_expression_completed(ib, gib, info) do
    Logger.debug "saving and registering new expression. info: #{inspect info}"

    ib_gib = Helper.get_ib_gib!(ib, gib)

    result =
      with {:ok, :ok} <- IbGib.Data.save(info),
           :ok <- IbGib.Expression.Registry.register(ib_gib, self),
        do: :ok

    if result == :ok do
      Logger.debug "Saved and registered ok. info: #{inspect info}"
      {:ok, %{:info => info}}
    else
      Logger.error "Save/Register error: #{inspect result}"
      {:error, result}
    end
  end

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
  @spec authorize_apply_b(map, map) :: list(String.t)
  defp authorize_apply_b(a_rel8ns, b_rel8ns) do
    Logger.warn "a_rel8ns: #{inspect a_rel8ns}"
    Logger.warn "b_rel8ns: #{inspect b_rel8ns}"
    a_has_identity =
      Map.has_key?(a_rel8ns, "identity") and
      length(a_rel8ns["identity"]) > 0
    b_has_identity =
      Map.has_key?(b_rel8ns, "identity") and
      length(b_rel8ns["identity"]) > 0

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
          # expected: a_identity, actual: b_identity
          Logger.error "DOH! Unidentified transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
          raise(UnauthorizedError, message:
            emsg_invalid_authorization(a_rel8ns["identity"],
                                       b_rel8ns["identity"]))
        end

      {false, true} ->
        # authorized: b has identity and a requires no authorization
        b_identity = b_rel8ns["identity"]

      {true, false} ->
        # unauthorized: a requires auth, b has none
        # expected: a_identity, actual: nil
        Logger.error "DOH! Unidentified transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
        raise UnauthorizedError, message: emsg_invalid_authorization(a_rel8ns["identity"], nil)

      {false, false} ->
        # unauthorized: b is required to have authorization and doesn't
        # expected: [something], actual: nil
        Logger.error "DOH! Unidentified transform apply attempt. Hack or mistake or what? \na_rel8ns:#{inspect a_rel8ns}\nb_rel8ns:#{inspect b_rel8ns}"
        raise UnauthorizedError, message: emsg_invalid_authorization([], nil)
    end
  end

  # ----------------------------------------------------------------------------
  # Client API - Meta
  # ----------------------------------------------------------------------------

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
  def fork(expr_pid,
           identity_ib_gibs,
           dest_ib,
           opts \\ @default_transform_options)
  def fork(expr_pid, identity_ib_gibs, dest_ib, opts)
    when is_pid(expr_pid) and is_list(identity_ib_gibs) and
         is_bitstring(dest_ib) and is_map(opts) do
    GenServer.call(expr_pid, {:fork, identity_ib_gibs, dest_ib, opts})
  end
  def fork(expr_pid, identity_ib_gibs, dest_ib, opts)
    when is_pid(expr_pid) and is_list(identity_ib_gibs) and
         is_bitstring(dest_ib) do
    Logger.debug "bad opts: #{inspect opts}"
    GenServer.call(expr_pid, {:fork, dest_ib, %{}})
  end

  @doc """
  Bang version of `fork/2`.
  """
  @spec fork!(pid, list(String.t), String.t, map) :: pid | any
  def fork!(expr_pid,
            identity_ib_gibs,
            dest_ib,
            opts \\ @default_transform_options)
  def fork!(expr_pid, identity_ib_gibs, dest_ib, opts)
    when is_pid(expr_pid) and is_list(identity_ib_gibs) and
         is_bitstring(dest_ib) and is_map(opts) do
    bang(fork(expr_pid, identity_ib_gibs, dest_ib, opts))
  end
  def fork!(expr_pid, identity_ib_gibs, dest_ib, opts)
    when is_pid(expr_pid) and is_list(identity_ib_gibs) and
         is_bitstring(dest_ib) do
    Logger.debug "bad opts: #{inspect opts}"
    bang(fork(expr_pid, identity_ib_gibs, dest_ib, %{}))
  end

  @doc """
  Mut8s given `expr_pid` internal `data` map, merging given `new_data` into
  it. By default, any keys in `new_data` will override any existing keys in
  `data`, but there are options for removing/renaming existing keys.

  See `IbGib.TransformFactory.Mut8Factory` for more details.
  """
  @spec mut8(pid, list(String.t), map, map) :: {:ok, pid} | {:error, any}
  def mut8(expr_pid,
           identity_ib_gibs,
           new_data,
           opts)
  def mut8(expr_pid, identity_ib_gibs, new_data, opts)
    when is_pid(expr_pid) and is_list(identity_ib_gibs) and
         is_map(new_data) and is_map(opts) do
    GenServer.call(expr_pid, {:mut8, identity_ib_gibs, new_data, opts})
  end
  def mut8(expr_pid, identity_ib_gibs, new_data, nil)
    when is_pid(expr_pid) and is_list(identity_ib_gibs) and
         is_map(new_data) do
    GenServer.call(expr_pid, {:mut8, identity_ib_gibs, new_data, %{}})
  end
  def mut8(expr_pid, identity_ib_gibs, new_data, opts) do
    # when is_pid(expr_pid) and is_list(identity_ib_gibs) and
    #      is_map(new_data) do
    Logger.debug "bad args: #{inspect [expr_pid, identity_ib_gibs, new_data, opts]}"
    # GenServer.call(expr_pid, {:mut8, identity_ib_gibs, new_data, %{}})
    {:error, emsg_invalid_args([expr_pid, identity_ib_gibs, new_data, opts])}
  end

  @doc """
  Bang version of `mut8/2`.
  """
  @spec mut8!(pid, list(String.t), map, map) :: pid | any
  def mut8!(expr_pid,
            identity_ib_gibs,
            new_data,
            opts \\ @default_transform_options)
  def mut8!(expr_pid, identity_ib_gibs, new_data, opts) do
    # when is_pid(expr_pid) and is_map(new_data) and is_map(opts) do
      bang(mut8(expr_pid, identity_ib_gibs, new_data, opts))
  end
  # def mut8!(expr_pid, new_data, opts)
  #   when is_pid(expr_pid) and is_map(new_data) do
  #     Logger.debug "bad opts: #{inspect opts}"
  #     bang(mut8(expr_pid, new_data, %{}))
  # end

  @doc """
  Relates the given source `expr_pid` to the destination `other_pid`. It will
  add `src_rel8ns` to the `expr_pid` rel8ns, and the similarly the `dest_rel8ns`
  will be added to the destination `other_pid`. The `opts` is currently used
  for "stamping" the gib.

  For example, say you want to relate A (A^gib) and B (B^gib) using the default
  rel8nship,
  which is "rel8d". You could simply call rel8(A_pid, B_pid), which will return
  {A_pid2, B_pid2}. A_pid2 info["rel8ns"] (a map) will now include the
  "rel8d" => ["B^gib"], and conversely B_pid2 info["rel8ns"] now has
  "rel8d" => ["A^gib"].

  Note that each of these relationships points to the other ib^gib **before**
  that ib_gib was rel8d. In other words, B2 will point to A1 and not A2, and
  vice versa. I'm still not sure of the implications of this, because it's a
  tough cookie to understand (chicken and egg issue).
  """
  @spec rel8(pid, pid, list(String.t), list(String.t), map) :: {:ok, {pid, pid}} | {:error, any}
  def rel8(expr_pid,
           other_pid,
           src_rel8ns \\ @default_rel8ns,
           dest_rel8ns \\ @default_rel8ns,
           opts \\ @default_transform_options)
  def rel8(expr_pid, other_pid, src_rel8ns, dest_rel8ns, opts)
    when is_pid(expr_pid) and is_pid(other_pid) and expr_pid !== other_pid and
         is_list(src_rel8ns) and length(src_rel8ns) >= 1 and
         is_list(dest_rel8ns) and length(dest_rel8ns) >= 1 and
         is_map(opts) do
    GenServer.call(expr_pid, {:rel8, other_pid, src_rel8ns, dest_rel8ns, opts})
  end
  def rel8(expr_pid, other_pid, src_rel8ns, dest_rel8ns, opts)
    when is_pid(expr_pid) and is_pid(other_pid) and expr_pid !== other_pid and
         is_list(src_rel8ns) and length(src_rel8ns) >= 1 and
         is_list(dest_rel8ns) and length(dest_rel8ns) >= 1 do
    Logger.debug "bad opts: #{inspect opts}"
    GenServer.call(expr_pid, {:rel8, other_pid, src_rel8ns, dest_rel8ns, %{}})
  end

  @doc """
  Bang version of `rel8/4`.
  """
  @spec rel8!(pid, pid, list(String.t), list(String.t), map) :: {pid, pid} | any
  def rel8!(expr_pid,
            other_pid,
            src_rel8ns \\ @default_rel8ns,
            dest_rel8ns \\ @default_rel8ns,
            opts \\ @default_transform_options)
  def rel8!(expr_pid, other_pid, src_rel8ns, dest_rel8ns, opts)
    when is_pid(expr_pid) and is_pid(other_pid) and expr_pid !== other_pid and
         is_list(src_rel8ns) and length(src_rel8ns) >= 1 and
         is_list(dest_rel8ns) and length(dest_rel8ns) >= 1 and
         is_map(opts) do
    bang(rel8(expr_pid, other_pid, src_rel8ns, dest_rel8ns, opts))
  end
  def rel8!(expr_pid, other_pid, src_rel8ns, dest_rel8ns, opts)
    when is_pid(expr_pid) and is_pid(other_pid) and expr_pid !== other_pid and
         is_list(src_rel8ns) and length(src_rel8ns) >= 1 and
         is_list(dest_rel8ns) and length(dest_rel8ns) >= 1 do
    Logger.debug "bad opts: #{inspect opts}"
    bang(rel8(expr_pid, other_pid, src_rel8ns, dest_rel8ns, %{}))
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
  # Example: `instance` will perform a `fork`, and then `rel8` each of the two
  # to each other, one ATOW rel8n is `instance` and the other is `instance_of`.
  # ----------------------------------------------------------------------------

  @doc """
  Forks the given `expr_pid`, and then relates the new forked expression to
  `expr_pid`.

  Returns a new version of the given `expr_pid` and the new forked expression.
  E.g. {pid_a0} returns {pid_a1, pid_a_instance)
  """
  @spec instance(pid, list(String.t), String.t, map) :: {:ok, {pid, pid}} | {:error, any}
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
  @spec instance!(pid, String.t, map) :: {pid, pid} | any
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
  def handle_call({:rel8, other_pid, src_rel8ns, dest_rel8ns, opts}, _from, state) do
    Logger.metadata([x: :rel8])
    {:ok, {new_this, new_other}} =
      rel8_impl(other_pid, src_rel8ns, dest_rel8ns, opts, state)
    {:reply, {:ok, {new_this, new_other}}, state}
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
    Logger.debug "identity_ib_gibs, dest_ib, opts, state: #{inspect [identity_ib_gibs, dest_ib, opts, state]}"
    info = state[:info]
    ib = info[:ib]
    gib = info[:gib]

    with {:ok, fork_info} <-
      # 1. Create transform
      TransformFactory.fork(Helper.get_ib_gib!(ib, gib), identity_ib_gibs, dest_ib, opts),

      # 2. Save transform
      {:ok, :ok} <- IbGib.Data.save(fork_info),

      # 3. Create instance process of fork
      {:ok, fork} <- IbGib.Expression.Supervisor.start_expression({fork_info[:ib], fork_info[:gib]}),

      # 4. Apply transform
      {:ok, new_pid} <- contact_impl(fork, state) do

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

  # ----------------------------------------------------------------------------
  # Server - mut8 impl
  # ----------------------------------------------------------------------------

  defp mut8_impl(identity_ib_gibs, new_data, opts, state) do
    info = state[:info]
    ib = info[:ib]
    gib = info[:gib]

    # 1. Create transform
    with {:ok, mut8_info} <-
      TransformFactory.mut8(Helper.get_ib_gib!(ib, gib), identity_ib_gibs, new_data, opts),

      # 2. Save transform
      {:ok, :ok} <- IbGib.Data.save(mut8_info),

      # 3. Create instance process of mut8
      {:ok, mut8} <- IbGib.Expression.Supervisor.start_expression({mut8_info[:ib], mut8_info[:gib]}),

      # 4. Apply transform
      {:ok, new_pid} <- contact_impl(mut8, state) do

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

  defp rel8_impl(other_pid, src_rel8ns, dest_rel8ns, opts, state) do
    Logger.debug "_state_: #{inspect state}"
    info = state[:info]

    # 1. Create transform
    this_ib_gib = Helper.get_ib_gib!(info[:ib], info[:gib])
    other_info = IbGib.Expression.get_info!(other_pid)
    other_ib_gib = Helper.get_ib_gib!(other_info[:ib], other_info[:gib])
    rel8_info = this_ib_gib |> TransformFactory.rel8(other_ib_gib, src_rel8ns, dest_rel8ns, opts)
    Logger.debug "rel8_info: #{inspect rel8_info}"

    # 2. Save transform
    {:ok, :ok} = IbGib.Data.save(rel8_info)

    # 3. Create instance process of rel8
    Logger.debug "rel8 saved. Now trying to create rel8 transform expression process"
    {:ok, rel8} = IbGib.Expression.Supervisor.start_expression({rel8_info[:ib], rel8_info[:gib]})

    # 4. Apply transform to both this and other
    Logger.debug "rel8 transform expression process created. Now will apply rel8 transform to this expression to create a new this..."
    {:ok, new_this} = contact_impl(rel8, state)
    Logger.debug "application successful. new_this: #{inspect new_this}"
    Logger.debug "Now will apply rel8 to the dest_ib_gib expression..."
    {:ok, new_other} = other_pid |> IbGib.Expression.contact(rel8)
    Logger.debug "application successful. new_other: #{inspect new_other}"
    {:ok, {new_this, new_other}}
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
    Logger.debug "_state_: #{inspect state}"
    Logger.debug "dest_ib: #{dest_ib}"

    # I think when we instance, we're just going to keep the same ib. It will
    # of course create a new gib hash. I think this is what we want to do...
    # I'm not sure!
    # info = state[:info]
    # fork_dest_ib = info[:ib]
    # fork_dest_ib = Helper.new_id
    {:ok, instance} = fork_impl(identity_ib_gibs, dest_ib, opts, state)
    Logger.debug "instance: #{inspect instance}"
    {:ok, {new_this, new_instance}} =
      rel8_impl(instance, ["instance"], ["instance_of"], opts, state)
    Logger.debug "new_this: #{inspect new_this}\nnew_instance: #{inspect new_instance}"
    {:ok, {new_this, new_instance}}
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
