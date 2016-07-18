defmodule IbGib.Expression do
  use GenServer
  require Logger

  alias IbGib.{TransformFactory, Helper}

  @delim "^"

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
          :relations => %{
            "history" => ["ib#{@delim}gib"]#,
            # "ancestor" => ["ib#{@delim}gib"],
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
      true ->
        err_msg = "unknown combination: a: #{inspect a}, b: #{inspect b}"
        Logger.error err_msg
        {:error, err_msg}
    end
  end

  defp apply_fork(a, b) do
    # We are applying a fork transform.
    Logger.debug "applying fork b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    Logger.debug "a[:relations]: #{inspect a[:relations]}"
    fork_data = b[:data]

    # We're going to borrow `a` as our own info for the new thing. We're just
    # going to change its `ib`, `gib`, and `relations`.

    # We take the ib directly from the fork's `dest_ib`.
    Logger.debug "Setting a[:ib]... fork_data: #{inspect fork_data}"
    ib = fork_data[:dest_ib]
    a = Map.put(a, :ib, ib)
    Logger.debug "a: #{inspect a}"

    # We add the fork itself to the `relations` `history`.
    a = a |> add_relation("history", b)
    Logger.debug "fork_data[:src_ib_gib]: #{fork_data[:src_ib_gib]}"
    a = a |> add_relation("ancestor", fork_data[:src_ib_gib])

    data = Map.get(a, :data, %{})
    Logger.debug "data: #{inspect data}"
    a = Map.put(a, :data, data)

    # Now we calculate the new hash and set it to `:gib`.
    gib = Helper.hash(ib, a[:relations], data)
    Logger.debug "gib: #{gib}"
    a = Map.put(a, :gib, gib)

    Logger.debug "a[:gib] set to gib: #{gib}"

    on_new_expression_completed(ib, gib, a)
  end

  defp apply_mut8(a, b) do
    # We are applying a mut8 transform.
    Logger.debug "applying mut8 b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    Logger.debug "a[:relations]: #{inspect a[:relations]}"

    # We're going to borrow `a` as our own info for the new thing. We're just
    # going to change its `gib`, and `relations`, and its `data` since it's
    # a mut8 transform.

    # the ib stays the same
    ib = a[:ib]
    Logger.debug "retaining ib. a[:ib]...: #{ib}"

    # We add the mut8 itself to the `relations`.
    a = a |> add_relation("history", b)

    a_data = Map.get(a, :data, %{})
    b_data = Map.get(b, :data, %{})
    # Adds/Overrides anything in `a_data` with `b_data`
    merged_data = Map.merge(a_data, b_data[:new_data])

    Logger.debug "merged data: #{inspect merged_data}"
    a = Map.put(a, :data, merged_data)

    # Now we calculate the new hash and set it to `:gib`.
    gib = Helper.hash(ib, a[:relations], merged_data)
    Logger.debug "gib: #{gib}"
    a = Map.put(a, :gib, gib)

    Logger.debug "a[:gib] set to gib: #{gib}"

    on_new_expression_completed(ib, gib, a)
  end

  defp apply_rel8(a, b) do
    # We are applying a rel8 transform.
    Logger.debug "applying rel8 b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    Logger.debug "a[:relations]: #{inspect a[:relations]}"

    # We add the rel8 transform to the history.
    a = a |> add_relation("history", b)

    # We need to know if we are source or destination of this rel8n.
    src_ib_gib = b[:data][:src_ib_gib]
    dest_ib_gib = b[:data][:dest_ib_gib]

    # Retaining ib because is a rel8 transform
    a_ib_gib = Helper.get_ib_gib!(a[:ib], a[:gib])

    {new_relations, other_ib_gib} =
      if (a_ib_gib === src_ib_gib) do
        {b[:data][:src_rel8ns], dest_ib_gib}
      else
        {b[:data][:dest_rel8ns], src_ib_gib}
      end
    Logger.debug "new_relations: #{inspect new_relations}, other_ib_gib: #{other_ib_gib}"
    new_a_relations =
      Enum.reduce(new_relations, a[:relations], fn(x, acc) ->
        if Map.has_key?(acc, x) and !Enum.member?(acc[x], other_ib_gib) do
          # We already have the key, so append it to the end of the list
          Map.put(acc, x, acc[x] ++ [other_ib_gib])
        else
          Map.put_new(acc, x, [other_ib_gib])
        end
      end)
    a = Map.put(a, :relations, new_a_relations)
    Logger.debug "new a: #{inspect a}"

    # Now we calculate the new hash and set it to `:gib`.
    ib = a[:ib]
    new_gib = Helper.hash(ib, a[:relations], a[:data])
    Logger.debug "new_gib: #{new_gib}"
    a = Map.put(a, :gib, new_gib)

    Logger.debug "a[:gib] set to gib: #{a[:gib]}"

    on_new_expression_completed(ib, new_gib, a)
  end

  defp add_relation(a, relation_name, b) when is_map(a) and is_bitstring(relation_name) and is_bitstring(b) do
    Logger.debug "Adding relation #{relation_name} to a. a[:relations]: #{inspect a[:relations]}"
    a_relations = a[:relations]

    relation = Map.get(a_relations, relation_name, [])
    new_relation = relation ++ [b]

    new_a_relations = Map.put(a_relations, relation_name, new_relation)
    new_a = Map.put(a, :relations, new_a_relations)
    Logger.debug "Added relation #{relation_name} to a. a[:relations]: #{inspect a[:relations]}"
    new_a
  end
  defp add_relation(a, relation_name, b) when is_map(a) and is_bitstring(relation_name) and is_map(b) do
    b_ib_gib = Helper.get_ib_gib!(b[:ib], b[:gib])
    add_relation(a, relation_name, b_ib_gib)
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
  #
  # ----------------------------------------------------------------------------

    @doc """
    Forks the given `expr_pid`, and then relates the new forked expression to
    `expr_pid`.

    Returns a new version of the given `expr_pid` and the new forked expression.
    E.g. {pid_a0} returns {pid_a1, pid_a_instance)
    """
    @spec instance(pid) :: {:ok, {pid, pid}} | {:error, any}
    def instance(expr_pid) when is_pid(expr_pid) do
      GenServer.call(expr_pid, :instance)
    end

    @doc """
    Bang version of `instance/1`.
    """
    @spec instance(pid) :: {:ok, {pid, pid}} | {:error, any}
    def instance!(expr_pid) when is_pid(expr_pid) do
      case instance(expr_pid) do
        {:ok, {new_expr_pid, instance_pid}} -> {new_expr_pid, instance_pid}
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
    next_info = next |> IbGib.Expression.get_info!
    next_other_info = next_other |> IbGib.Expression.get_info!
    next_ib_gib = Helper.get_ib_gib!(next_info[:ib], next_info[:gib])
    next_other_ib_gib = Helper.get_ib_gib!(next_other_info[:ib], next_other_info[:gib])
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
    IbGib.Data.save(mut8_info)

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
  def handle_call(:instance, _from, state) do
    {:reply, instance_impl(state), state}
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
    IbGib.Data.save(fork_info)

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
    IbGib.Data.save(rel8_info)

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

  defp instance_impl(state) do
    Logger.debug "_state_: #{inspect state}"
    info = state[:info]

    # I think when we instance, we're just going to keep the same ib. It will
    # of course create a new gib hash. I think this is what we want to do...
    # I'm not sure!
    # fork_dest_ib = info[:ib]
    fork_dest_ib = Helper.new_id
    {:ok, instance} = fork_impl(fork_dest_ib, state)
    Logger.debug "instance: #{inspect instance}"
    {:ok, {new_this, new_instance}} =
      rel8_impl(instance, ["instance"], ["instance_of"], state)
    Logger.debug "new_this: #{inspect new_this}\nnew_instance: #{inspect new_instance}"
    {:ok, {new_this, new_instance}}
  end

  defp contact_impl(other_pid, state) when is_pid(other_pid) and is_map(state) do
    Logger.debug "state: #{inspect state}"
    Logger.debug "other_expr_pid: #{inspect other_pid}"

    {:ok, other_info} = get_info(other_pid)
    Logger.debug "other_info: #{inspect other_info}"
    IbGib.Expression.Supervisor.start_expression({state[:info], other_info})
  end
end
