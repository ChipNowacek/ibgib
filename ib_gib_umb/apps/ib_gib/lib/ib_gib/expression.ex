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

    {:combine, {a, b}} - Use this to create a new ib_gib, usually when applying
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
  def start_link({:combine, {a, b}}) when is_map(a) and is_map(b) do
    # expr_id = Helper.new_id |> String.downcase
    Logger.debug "{a, b}: {#{inspect a}, #{inspect b}}"
    result = GenServer.start_link(__MODULE__, {:combine, {a, b}})
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
  def init({:combine, {a, b}}) when is_map(a) and is_map(b) do
    Logger.metadata([x: :combine])
    cond do
      b[:ib] === "fork" and b[:gib] !== "gib" ->
        combine_fork(a, b)
      b[:ib] === "mut8" and b[:gib] !== "gib" ->
        combine_mut8(a, b)
      true ->
        err_msg = "unknown combination: a: #{inspect a}, b: #{inspect b}"
        Logger.error err_msg
        {:error, err_msg}
    end
  end

  defp combine_fork(a, b) do
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

  defp combine_mut8(a, b) do
    # We are applying a mut8 transform.
    Logger.debug "applying mut8 b to ib_gib a.\na: #{inspect a}\nb: #{inspect b}\n"
    Logger.debug "a[:relations]: #{inspect a[:relations]}"
    # b_data = b[:data]

    # We're going to borrow `a` as our own info for the new thing. We're just
    # going to change its `gib`, and `relations`, and its `data` since it's
    # a mut8 transform.

    # the ib stays the same
    ib = a[:ib]
    Logger.debug "retaining ib. a[:ib]...: #{ib}"

    # We add the mut8 itself to the `relations`.
    a = a |> add_relation("history", b)
    # {:ok, a, new_relations} = add_b_to_history(a, b)

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

  # defp add_b_to_history(a, b) do
  #   Logger.debug "Setting a[:relations][\"history\"] to include mut8 that we're applying..."
  #   b_ib_gib = Helper.get_ib_gib!(b[:ib], b[:gib])
  #   a_relations = a[:relations]
  #   a_history = a_relations["history"]
  #   new_history = a_history ++ [b_ib_gib]
  #
  #   Logger.debug "new_history: #{inspect new_history}"
  #   new_relations = Map.put(a_relations, "history", new_history)
  #   new_a = Map.put(a, :relations, new_relations)
  #   {:ok, new_a, new_relations}
  # end

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
  "Combines" two expression processes. This is usually going to be "apply
  transform".
  """
  def meet(expr_pid, other_expr_pid) when is_pid(expr_pid) and is_pid(other_expr_pid) do
    GenServer.call(expr_pid, {:meet, other_expr_pid})
  end

  @doc """
  Creates a fork of this expression process, saves it, creates a new,
  registered expression process with the fork. All internal `data` is
  copied in the fork process.

  Returns the new forked process' pid or an error.
  """
  def fork(expr_pid, dest_ib \\ Helper.new_id) when is_pid(expr_pid) and is_bitstring(dest_ib) do
    GenServer.call(expr_pid, {:fork, dest_ib})
  end
  def fork!(expr_pid, dest_ib \\ Helper.new_id) when is_pid(expr_pid) and is_bitstring(dest_ib) do
    case fork(expr_pid, dest_ib) do
      {:ok, new_pid} -> new_pid
      {:error, reason} -> raise "#{inspect reason}"
    end
  end

  def mut8(expr_pid, new_data) when is_pid(expr_pid) and is_map(new_data) do
    GenServer.call(expr_pid, {:mut8, new_data})
  end
  def mut8!(expr_pid, new_data) when is_pid(expr_pid) and is_map(new_data) do
    case mut8(expr_pid, new_data) do
      {:ok, new_pid} -> new_pid
      {:error, reason} -> raise "#{inspect reason}"
    end
  end

  # def merge(expr_pid, new_data) when is_pid(expr_pid) and is_map(new_data) do
  #   GenServer.call(expr_pid, {:merge, new_data})
  # end
  # def merge!(expr_pid, new_data) when is_pid(expr_pid) and is_map(new_data) do
  #   case merge(expr_pid, new_data) do
  #     {:ok, new_pid} -> new_pid
  #     {:error, reason} -> raise "#{inspect reason}"
  #   end
  # end

  def get_info(expr_pid) when is_pid(expr_pid) do
    GenServer.call(expr_pid, :get_info)
  end
  def get_info!(expr_pid) when is_pid(expr_pid) do
    {:ok, result} = GenServer.call(expr_pid, :get_info)
    result
  end

  # ----------------------------------------------------------------------------
  # Server
  # ----------------------------------------------------------------------------

  def handle_call({:meet, other_expr_pid}, _from, state) do
    Logger.metadata([x: :meet])
    Logger.debug ":ib_gib"
    {:reply, meet_impl(other_expr_pid, state), state}
  end
  def handle_call({:fork, dest_ib}, _from, state) do
    Logger.metadata([x: :fork])
    Logger.debug "state: #{inspect state}"
    info = state[:info]
    Logger.debug "info: #{inspect info}"
    ib = info[:ib]
    gib = info[:gib]
    Logger.debug "ib: #{inspect ib}"

    # 1. Create transform
    fork_info = TransformFactory.fork(Helper.get_ib_gib!(ib, gib), dest_ib)
    Logger.debug "fork_info: #{inspect fork_info}"

    # 2. Save transform
    IbGib.Data.save(fork_info)

    # 3. Create instance process of fork
    Logger.debug "fork saved. Now trying to create fork transform expression process"
    {:ok, fork} = IbGib.Expression.Supervisor.start_expression({fork_info[:ib], fork_info[:gib]})

    # 4. Apply transform
    Logger.debug "will ib_gib the fork..."
    meet_result = meet_impl(fork, state)
    Logger.debug "meet_result: #{inspect meet_result}"

    {:reply, meet_result, state}
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
    meet_result = meet_impl(mut8, state)
    Logger.debug "meet_result: #{inspect meet_result}"

    {:reply, meet_result, state}
  end
  # def handle_call({:merge, new_data}, _from, state) do
  #   Logger.metadata([x: :merge])
  #   Logger.debug "state: #{inspect state}"
  #   info = state[:info]
  #   Logger.debug "info: #{inspect info}"
  #   ib = info[:ib]
  #   gib = info[:gib]
  #   Logger.debug "ib: #{inspect ib}"
  #
  #   # 1. Create transform
  #   merge_info = TransformFactory.merge(Helper.get_ib_gib!(ib, gib), new_data)
  #   Logger.debug "merge_info: #{inspect merge_info}"
  #
  #   # 2. Save transform
  #   IbGib.Data.save(merge_info)
  #
  #   # 3. Create instance process of merge
  #   Logger.debug "merge saved. Now trying to create merge transform expression process"
  #   {:ok, merge} = IbGib.Expression.Supervisor.start_expression({merge_info[:ib], merge_info[:gib]})
  #
  #   # 4. Apply transform
  #   Logger.debug "will ib_gib the merge..."
  #   meet_result = meet_impl(merge, state)
  #   Logger.debug "meet_result: #{inspect meet_result}"
  #
  #   {:reply, meet_result, state}
  # end
  def handle_call(:get_info, _from, state) do
    Logger.metadata([x: :get_info])
    {:reply, {:ok, state[:info]}, state}
  end

  defp meet_impl(other_expr_pid, state) when is_pid(other_expr_pid) and is_map(state) do
    Logger.debug "state: #{inspect state}"
    Logger.debug "other_expr_pid: #{inspect other_expr_pid}"

    {:ok, other_info} = get_info(other_expr_pid)
    Logger.debug "other_info: #{inspect other_info}"
    IbGib.Expression.Supervisor.start_expression({state[:info], other_info})
  end
end
