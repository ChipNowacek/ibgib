defmodule IbGib.Expression do
  use GenServer
  require Logger
  import Enum

  use IbGib.Constants, :ib_gib
  alias IbGib.{TransformFactory, Helper}

  @moduledoc """

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
  """

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
    result = GenServer.start_link(__MODULE__, {:ib_gib, {ib, gib}})
    Logger.debug "start_link result: #{inspect result}"
    result
  end
  def start_link({:apply, {a, b}}) when is_map(a) and is_map(b) do
    # expr_id = Helper.new_id |> String.downcase
    Logger.debug "{a, b}: {#{inspect a}, #{inspect b}}"
    result = GenServer.start_link(__MODULE__, {:apply, {a, b}})
    Logger.debug "start_link result: #{inspect result}"
    result
  end

  # ----------------------------------------------------------------------------
  # Inits
  # ----------------------------------------------------------------------------
  def init({:ib_gib, {ib, gib}}) when is_bitstring(ib) and is_bitstring(gib) do
    Logger.metadata([x: :ib_gib])
    info =
      if ib === "ib" and gib === "gib" do
        Logger.debug "initializing ib_gib root expression."
        %{
          :ib => ib,
          :gib => gib,
          :rel8ns => %{
            "history" => default_history#,
            # "ancestor" => ["ib#{delim}gib"],
            },
          :data => %{}
        }
      else
        Logger.debug "initializing ib_gib expression by loading data. ib: #{ib}, gib: #{gib}"
        IbGib.Data.load!(ib, gib)
      end
    register_result = IbGib.Expression.Registry.register(Helper.get_ib_gib!(ib, gib), self)
    if (register_result === :ok) do
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

  # ----------------------------------------------------------------------------
  # Apply Functions
  # We are within an init of a new process, and we are apply given `b`
  # ib_gib info map (transform/query) to a given `a` "starting point" ib_gib
  # info map. See moduledoc for more details.0
  # ----------------------------------------------------------------------------
  defp apply_fork(a, b) do
    # We are applying a fork transform.
    Logger.debug "applying fork b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    Logger.debug "a[:rel8ns]: #{inspect a[:rel8ns]}"
    fork_data = b[:data]
    # b_ib_gib = Helper.get_ib_gib!(b[:ib], b[:gib])

    # We're going to populate this with data from `a` and `b`.
    this_info = %{}
    Logger.debug "this_info: #{inspect this_info}"

    # We take the ib directly from the fork's `dest_ib`.
    this_ib = fork_data["dest_ib"]
    this_info = Map.put(this_info, :ib, this_ib)
    Logger.debug "this_info: #{inspect this_info}"

    # rel8ns is tricky. Should we by default keep rel8ns except past?
    # Or should we reset and only bring over `history` and `ancestor`? Others?
    # tricky...
    a_history = Map.get(a[:rel8ns], "history", [])
    a_ancestor = Map.get(a[:rel8ns], "ancestor", [])
    this_rel8ns = %{
      "history" => a_history,
      "ancestor" => a_ancestor
    }
    Logger.warn "this_rel8ns: #{inspect this_rel8ns}"
    this_info = Map.put(this_info, :rel8ns, this_rel8ns)
    Logger.debug "this_info: #{inspect this_info}"

    # We add the fork itself to the relations `history`.
    this_info = this_info |> add_relation("history", b)
    Logger.debug "fork_data[\"src_ib_gib\"]: #{fork_data["src_ib_gib"]}"
    this_info = this_info |> add_relation("ancestor", fork_data["src_ib_gib"])
    Logger.debug "this_info: #{inspect this_info}"

    # Copy the data over. Data is considered to be "small", so should be
    # copyable.
    this_data = Map.get(a, :data, %{})
    this_info = Map.put(this_info, :data, this_data)
    Logger.debug "this_info: #{inspect this_info}"

    # Now we calculate the new hash and set it to `:gib`.
    this_gib = Helper.hash(this_ib, this_info[:rel8ns], this_data)
    this_info = Map.put(this_info, :gib, this_gib)
    Logger.debug "this_info: #{inspect this_info}"

    on_new_expression_completed(this_ib, this_gib, this_info)
  end

  defp apply_mut8(a, b) do
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

    # We add the mut8 itself to the `relations`.
    a = a
        |> add_relation("past", original_ib_gib)
        |> add_relation("history", b)

    a_data = Map.get(a, :data, %{})
    b_data = Map.get(b, :data, %{})
    Logger.debug "a_data: #{inspect a_data}\nb_data: #{inspect b_data}"
    # Adds/Overrides anything in `a_data` with `b_data`
    merged_data = Map.merge(a_data, b_data["new_data"])

    Logger.debug "merged data: #{inspect merged_data}"
    a = Map.put(a, :data, merged_data)

    # Now we calculate the new hash and set it to `:gib`.
    gib = Helper.hash(ib, a[:rel8ns], merged_data)
    Logger.debug "gib: #{gib}"
    a = Map.put(a, :gib, gib)

    Logger.debug "a[:gib] set to gib: #{gib}"

    on_new_expression_completed(ib, gib, a)
  end

  defp apply_rel8(a, b) do
    # We are applying a rel8 transform.
    Logger.debug "applying rel8 b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    Logger.debug "a[:rel8ns]: #{inspect a[:rel8ns]}"

    # We add the rel8 transform to the history.
    a = a |> add_relation("history", b)

    # We need to know if we are source or destination of this rel8n.
    src_ib_gib = b[:data]["src_ib_gib"]
    dest_ib_gib = b[:data]["dest_ib_gib"]

    # Retaining ib because is a rel8 transform
    a_ib_gib = Helper.get_ib_gib!(a[:ib], a[:gib])

    {new_relations, other_ib_gib} =
      if (a_ib_gib === src_ib_gib) do
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
    new_gib = Helper.hash(ib, a[:rel8ns], a[:data])
    Logger.debug "new_gib: #{new_gib}"
    a = Map.put(a, :gib, new_gib)

    Logger.debug "a[:gib] set to gib: #{a[:gib]}"

    on_new_expression_completed(ib, new_gib, a)
  end

  defp apply_query(a, b) do
    query_options = b[:data]["options"]
    result = IbGib.Data.query(query_options)
    Logger.warn "query result: #{inspect result}"

    # debug
    result_as_list =
      result |> reduce([], fn(ib_gib_model, acc) ->
        acc ++ [Helper.get_ib_gib!(ib_gib_model.ib, ib_gib_model.gib)]
      end)
    Logger.warn "query result_as_list: #{inspect result_as_list}"

    this_info = %{}
    this_ib = "queryresult"
    this_info = Map.put(this_info, :ib, this_ib)
    this_data = %{"result_count" => "#{Enum.count(result)}"}
    this_rel8ns = %{"history" => default_history, "ancestor" => ["queryresult^gib"]}
    this_info =
      this_info
      |> Map.put(:ib, this_ib)
      |> Map.put(:data, this_data)
      |> Map.put(:rel8ns, this_rel8ns)
      |> add_relation("history", b)
      |> add_relation(
          "result",
          result |> reduce([], fn(ib_gib_model, acc) ->
            acc ++ [Helper.get_ib_gib!(ib_gib_model.ib, ib_gib_model.gib)]
          end))

    this_gib = Helper.hash(this_ib, this_info[:rel8ns], this_info[:data])
    this_info = Map.put(this_info, :gib, this_gib)

    Logger.debug "this_info is built yo! this_info: #{inspect this_info}"
    on_new_expression_completed(this_ib, this_gib, this_info)
  end


  defp add_relation(a, relation_name, b) when is_map(a) and is_bitstring(relation_name) and is_bitstring(b) do
    # Logger.debug "bitstring yo"
    add_relation(a, relation_name, [b])
  end
  defp add_relation(a, relation_name, b) when is_map(a) and is_bitstring(relation_name) and is_list(b) do
    # Logger.debug "array list"
    b_is_list_of_ib_gib =
      b |> all?(fn(item) -> Helper.valid_ib_gib?(item) end)

    if (b_is_list_of_ib_gib) do
      Logger.debug "Adding relation #{relation_name} to a. a[:rel8ns]: #{inspect a[:rel8ns]}"
      a_relations = a[:rel8ns]

      relation = Map.get(a_relations, relation_name, [])
      new_relation = relation ++ b

      new_a_relations = Map.put(a_relations, relation_name, new_relation)
      new_a = Map.put(a, :rel8ns, new_a_relations)
      Logger.debug "Added relation #{relation_name} to a. a[:rel8ns]: #{inspect a[:rel8ns]}"
      new_a
    else
      Logger.warn "Tried to add relation list of non-valid ib_gib."
      a
    end
  end
  defp add_relation(a, relation_name, b) when is_map(a) and is_bitstring(relation_name) and is_map(b) do
    # Logger.debug "mappy mappy"
    b_ib_gib = Helper.get_ib_gib!(b[:ib], b[:gib])
    add_relation(a, relation_name, [b_ib_gib])
  end

  defp on_new_expression_completed(ib, gib, info) do
    Logger.debug "saving and registering new expression. info: #{inspect info}"

    ib_gib = Helper.get_ib_gib!(ib, gib)

    result =
      with {:ok, :ok} <- IbGib.Data.save(info),
           :ok <- IbGib.Expression.Registry.register(ib_gib, self),
        do: :ok

    if (result === :ok) do
      Logger.debug "Saved and registered ok. info: #{inspect info}"
      {:ok, %{:info => info}}
    else
      Logger.error "Save/Register error: #{inspect result}"
      {:error, result}
    end
  end

  # ----------------------------------------------------------------------------
  # Client API
  # ----------------------------------------------------------------------------

  @doc """
  "applys" two expression processes. This is usually going to be "apply
  transform".
  """
  def contact(this_pid, that_pid) when is_pid(this_pid) and is_pid(that_pid) do
    GenServer.call(this_pid, {:contact, that_pid})
  end

  # ----------------------------------------------------------------------------
  # Core Transforms
  # ----------------------------------------------------------------------------

  @doc """
  Creates a fork of this expression process, saves it, creates a new,
  registered expression process with the fork. All internal `data` is
  copied in the fork process.

  Returns the new forked process' pid or an error.
  """
  @spec fork(pid, String.t) :: {:ok, pid} | {:error, any}
  def fork(expr_pid, dest_ib \\ Helper.new_id) when is_pid(expr_pid) and is_bitstring(dest_ib) do
    GenServer.call(expr_pid, {:fork, dest_ib})
  end

  @doc """
  Bang version of `fork/2`.
  """
  @spec fork!(pid, String.t) :: pid | any
  def fork!(expr_pid, dest_ib \\ Helper.new_id)
    when is_pid(expr_pid) and is_bitstring(dest_ib) do
    case fork(expr_pid, dest_ib) do
      {:ok, new_pid} -> new_pid
      {:error, reason} -> raise "#{inspect reason}"
    end
  end

  @doc """
  Mut8s given `expr_pid` internal `data` map, merging given `new_data` into
  it. Any keys in `new_data` will override any existing keys in `data`.
  """
  @spec mut8(pid, map) :: {:ok, pid} | {:error, any}
  def mut8(expr_pid, new_data) when is_pid(expr_pid) and is_map(new_data) do
    GenServer.call(expr_pid, {:mut8, new_data})
  end

  @doc """
  Bang version of `mut8/2`.
  """
  @spec mut8(pid, map) :: pid | any
  def mut8!(expr_pid, new_data)
    when is_pid(expr_pid) and is_map(new_data) do
    case mut8(expr_pid, new_data) do
      {:ok, new_pid} -> new_pid
      {:error, reason} -> raise "#{inspect reason}"
    end
  end

  @default_rel8ns ["rel8d"]

  @spec rel8(pid, pid, list(String.t), list(String.t)) :: {:ok, {pid, pid}} | {:error, any}
  def rel8(expr_pid, other_pid, src_rel8ns \\ @default_rel8ns, dest_rel8ns \\ @default_rel8ns)
    when is_pid(expr_pid) and is_pid(other_pid) and expr_pid !== other_pid and
         is_list(src_rel8ns) and length(src_rel8ns) >= 1 and
         is_list(dest_rel8ns) and length(dest_rel8ns) >= 1  do
    GenServer.call(expr_pid, {:rel8, other_pid, src_rel8ns, dest_rel8ns})
  end

  @doc """
  Bang version of `rel8/4`.
  """
  @spec rel8(pid, pid, list(String.t), list(String.t)) :: {pid, pid} | any
  def rel8!(expr_pid, other_pid, src_rel8ns \\ @default_rel8ns, dest_rel8ns \\ @default_rel8ns)
    when is_pid(expr_pid) and is_pid(other_pid) and expr_pid !== other_pid and
         is_list(src_rel8ns) and length(src_rel8ns) >= 1 and
         is_list(dest_rel8ns) and length(dest_rel8ns) >= 1  do
    case rel8(expr_pid, other_pid, src_rel8ns, dest_rel8ns) do
      {:ok, {new_expr_pid, new_other_pid}} -> {new_expr_pid, new_other_pid}
      {:error, reason} -> raise "#{inspect reason}"
    end
  end

  # ----------------------------------------------------------------------------
  # Complex Factory Functions
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
    @spec instance(pid, String.t) :: {:ok, {pid, pid}} | {:error, any}
    def instance(expr_pid, dest_ib \\ Helper.new_id) when is_pid(expr_pid) and is_bitstring(dest_ib) do
      GenServer.call(expr_pid, {:instance, dest_ib})
    end

    @doc """
    Bang version of `instance/2`.
    """
    @spec instance!(pid, String.t) :: {pid, pid} | any
    def instance!(expr_pid, dest_ib \\ Helper.new_id) when is_pid(expr_pid) and is_bitstring(dest_ib) do
      case instance(expr_pid, dest_ib) do
        {:ok, {new_expr_pid, instance_pid}} -> {new_expr_pid, instance_pid}
        {:error, reason} -> raise "#{inspect reason}"
      end
    end

    @doc """
    Ok, this creates an ib_gib that contains the query info passed in with the
    various given options maps. (This is similar to creating a fork, mut8, or
    rel8 transform.) It then "applies" this query, which then goes off and
    actually populates the results of the query. These results are then stored
    in another ib_gib.

    ## Returns
    Returns `{:ok, qry_results_expr_pid}` which is the reference to the newly
    generated queryresults ib_gib (not the query "transform" ib_gib).
    """
    @spec query(pid, map, map, map, map, map) :: {:ok, pid} | {:error, any}
    def query(expr_pid, ib_options, data_options, rel8ns_options, time_options, meta_options)
      when is_pid(expr_pid) and
           is_map(ib_options) and is_map(data_options) and
           is_map(rel8ns_options) and is_map(time_options) and
           is_map(meta_options) do
      GenServer.call(expr_pid, {:query, ib_options, data_options, rel8ns_options, time_options, meta_options})
    end

    @doc """
    Bang version of `query/6`
    """
    @spec query!(pid, map, map, map, map, map) :: pid | any
    def query!(expr_pid, ib_options, data_options, rel8ns_options, time_options, meta_options)
      when is_pid(expr_pid) and
           is_map(ib_options) and is_map(data_options) and
           is_map(rel8ns_options) and is_map(time_options) and
           is_map(meta_options) do
      case query(expr_pid, ib_options, data_options, rel8ns_options, time_options, meta_options) do
        {:ok, qry_results_expr_pid} -> qry_results_expr_pid
        {:error, reason} -> raise "#{inspect reason}"
      end
    end

  # ----------------------------------------------------------------------------
  # Gib Versions _(return additional information)_
  # ----------------------------------------------------------------------------

  @doc """
  `gib` versions of `fork`, `mut8`, and `rel8` both perform the relevant
  operation and return the info as well as the ib_gib of the new thing.
  """
  def gib(expr_pid, :fork, dest_ib) do
    next = expr_pid |> fork!(dest_ib)
    next_info = next |> IbGib.Expression.get_info!
    next_ib_gib = Helper.get_ib_gib!(next_info[:ib], next_info[:gib])
    {:ok, {next, next_info, next_ib_gib}}
  end
  def gib(expr_pid, :mut8, new_data) do
    next = expr_pid |> mut8!(new_data)
    next_info = next |> IbGib.Expression.get_info!
    next_ib_gib = Helper.get_ib_gib!(next_info[:ib], next_info[:gib])
    {:ok, {next, next_info, next_ib_gib}}
  end

  def gib(expr_pid, :rel8, other_pid, src_rel8ns \\ @default_rel8ns, dest_rel8ns \\ @default_rel8ns) do
    {next, next_other} = IbGib.Expression.rel8!(expr_pid, other_pid, src_rel8ns, dest_rel8ns)
    Logger.warn "a"
    next_info = next |> IbGib.Expression.get_info!
    Logger.warn "b"
    next_other_info = next_other |> IbGib.Expression.get_info!
    Logger.warn "c"
    next_ib_gib = Helper.get_ib_gib!(next_info[:ib], next_info[:gib])
    Logger.warn "d"
    next_other_ib_gib = Helper.get_ib_gib!(next_other_info[:ib], next_other_info[:gib])
    Logger.warn "e"
    {
      :ok,
      {next, next_info, next_ib_gib},
      {next_other, next_other_info, next_other_ib_gib}
    }
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
    Logger.debug ":ib_gib"
    {:reply, contact_impl(other_expr_pid, state), state}
  end
  def handle_call({:fork, dest_ib}, _from, state) do
    {:reply, fork_impl(dest_ib, state), state}
  end
  def handle_call({:mut8, new_data}, _from, state) do
    Logger.metadata([x: :mut8])
    Logger.debug "state: #{inspect state}"
    info = state[:info]
    Logger.debug "info: #{inspect info}"
    ib = info[:ib]
    gib = info[:gib]
    Logger.debug "ib: #{inspect ib}"

    # 1. Create transform
    mut8_info = TransformFactory.mut8(Helper.get_ib_gib!(ib, gib), new_data)
    Logger.debug "mut8_info: #{inspect mut8_info}"

    # 2. Save transform
    {:ok, :ok} = IbGib.Data.save(mut8_info)

    # 3. Create instance process of mut8
    Logger.debug "mut8 saved. Now trying to create mut8 transform expression process"
    {:ok, mut8} = IbGib.Expression.Supervisor.start_expression({mut8_info[:ib], mut8_info[:gib]})

    # 4. Apply transform
    Logger.debug "will ib_gib the mut8..."
    contact_result = contact_impl(mut8, state)
    Logger.debug "contact_result: #{inspect contact_result}"

    {:reply, contact_result, state}
  end
  def handle_call({:rel8, other_pid, src_rel8ns, dest_rel8ns}, _from, state) do
    {:ok, {new_this, new_other}} =
      rel8_impl(other_pid, src_rel8ns, dest_rel8ns, state)
    {:reply, {:ok, {new_this, new_other}}, state}
  end
  def handle_call({:instance, dest_ib}, _from, state) do
    Logger.debug "dest_ib: #{dest_ib}"
    {:reply, instance_impl(dest_ib, state), state}
  end
  def handle_call({:query, ib_options, data_options, rel8ns_options, time_options, meta_options}, _from, state) do
    Logger.warn "ib_options: #{inspect ib_options}\ndata_options: #{inspect data_options}\nrel8ns_options: #{inspect rel8ns_options}\ntime_options: #{inspect time_options}\nmeta_options: #{inspect meta_options}"
    {:reply, query_impl(ib_options, data_options, rel8ns_options, time_options, meta_options, state), state}
  end
  def handle_call(:get_info, _from, state) do
    Logger.metadata([x: :get_info])
    {:reply, {:ok, state[:info]}, state}
  end

  defp fork_impl(dest_ib, state) do
    Logger.debug "state: #{inspect state}"
    info = state[:info]
    ib = info[:ib]
    gib = info[:gib]

    # 1. Create transform
    fork_info = TransformFactory.fork(Helper.get_ib_gib!(ib, gib), dest_ib)
    Logger.debug "fork_info: #{inspect fork_info}"

    # 2. Save transform
    {:ok, :ok} = IbGib.Data.save(fork_info)

    # 3. Create instance process of fork
    Logger.debug "fork saved. Now trying to create fork transform expression process"
    {:ok, fork} = IbGib.Expression.Supervisor.start_expression({fork_info[:ib], fork_info[:gib]})

    # 4. Apply transform
    contact_result = contact_impl(fork, state)
    Logger.debug "contact_result: #{inspect contact_result}"
    contact_result
  end

  defp rel8_impl(other_pid, src_rel8ns, dest_rel8ns, state) do
    Logger.debug "_state_: #{inspect state}"
    info = state[:info]

    # 1. Create transform
    this_ib_gib = Helper.get_ib_gib!(info[:ib], info[:gib])
    other_info = IbGib.Expression.get_info!(other_pid)
    other_ib_gib = Helper.get_ib_gib!(other_info[:ib], other_info[:gib])
    rel8_info = this_ib_gib |> TransformFactory.rel8(other_ib_gib, src_rel8ns, dest_rel8ns)
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

  defp instance_impl(dest_ib, state) do
    Logger.debug "_state_: #{inspect state}"
    Logger.warn "dest_ib: #{dest_ib}"

    # I think when we instance, we're just going to keep the same ib. It will
    # of course create a new gib hash. I think this is what we want to do...
    # I'm not sure!
    # info = state[:info]
    # fork_dest_ib = info[:ib]
    # fork_dest_ib = Helper.new_id
    {:ok, instance} = fork_impl(dest_ib, state)
    Logger.debug "instance: #{inspect instance}"
    {:ok, {new_this, new_instance}} =
      rel8_impl(instance, ["instance"], ["instance_of"], state)
    Logger.debug "new_this: #{inspect new_this}\nnew_instance: #{inspect new_instance}"
    {:ok, {new_this, new_instance}}
  end

  defp query_impl(ib_options, data_options, rel8ns_options, time_options, meta_options, state)
    when is_map(ib_options) and is_map(data_options) and
         is_map(rel8ns_options) and is_map(time_options) and
         is_map(meta_options) do
    Logger.debug "_state_: #{inspect state}"

    # 1. Create query ib_gib
    query_info = TransformFactory.query(ib_options, data_options, rel8ns_options, time_options, meta_options)
    Logger.debug "query_info: #{inspect query_info}"

    # 2. Save query ib_gib
    {:ok, :ok} = IbGib.Data.save(query_info)

    # 3. Create instance process of query
    Logger.debug "query saved. Now trying to create query expression process."
    {:ok, query} = IbGib.Expression.Supervisor.start_expression({query_info[:ib], query_info[:gib]})

    # 4. Create new ib_gib by contacting query ib_gib
    contact_result = contact_impl(query, state)
    Logger.debug "contact_result: #{inspect contact_result}"
    contact_result
  end

  defp contact_impl(other_pid, state) when is_pid(other_pid) and is_map(state) do
    Logger.debug "state: #{inspect state}"
    Logger.debug "other_expr_pid: #{inspect other_pid}"

    {:ok, other_info} = get_info(other_pid)
    Logger.debug "other_info: #{inspect other_info}"
    IbGib.Expression.Supervisor.start_expression({state[:info], other_info})
  end
end
