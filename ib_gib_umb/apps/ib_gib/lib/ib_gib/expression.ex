defmodule IbGib.Expression do
  @moduledoc """
  This is the primary module right now for the IbGib engine. Basically an
  `IbGib.Expression` encapsulates functionality for "expressing" ib_gib.

  For starters, you can think of ib_gib as "things" or "objects". The term also
  will refer to the "name" of a "thing" or "object", represented by an "id"
  (the `ib`) and the "hash" (the `gib`). When you see the term with a `^`, this
  refers specifically to the "pointer" for the ib_gib. Or if you like thinking
  in terms of content addressable storage, the ib^gib refers to the "address" of
  an ib_gib, defined as its `ib` + the delim (`^`) + its `gib`. Examples of this
  include "ib^gib" to refer to the root ib_gib, "fork^gib", to refer to the
  root fork transform, "some ib^ABC123" to refer to some example ib_gib.

  "Expression" is the process by which we "create new" ib_gib or "load existing"
  ib_gib.

  ## Loading Existing ib_gib

  If we pass in an ib^gib to `IbGib.Expression.Supervisor`, then it
  will attempt to find an existing ib_gib process. If not found, it will look
  in an ets cache, and if still not found it will look in the repo.
  express an ib_gib that already exists in our repo, for instance, then it
  will create an `IbGib.Expression` process (supervised by the
  `IbGib.Expression.Supervisor`) and hydrate its state from the repo.

  ## Creating "New" ib_gib: `fork`, `mut8`, `rel8`

  From a caller's POV, to create an ib_gib, we will usually call one of the
  main public API functions: `fork`, `mut8`, `rel8`, `query`, or other
  functions that are built on top of these, e.g. `instance` (which is a `fork`
  with a subsequent `rel8`).

  In the OOP paradigm, when we think of something "new", we usually mean
  calling a constructor on a new instance of something. In ibGib, we mean that
  we are transforming state to create some other state.

  This can be a `fork`, which creates a "new" thing based off of some existing
  one, and then adds the existing one to its "ancestor" relationship. In OOP,
  this is similar to inheritance in a class heirarchy or a prototypal
  inheritance.

  Or it can be a `mut8`, which takes an existing thing and changes its internal
  `data`. When mut8ing, we will create a relationship of the new thing with the
  old by adding a "past" rel8n pointing to the original ib^gib.

  We can also `rel8` things, which is like a mut8n, but changing an ib_gib's
  `rel8ns` instead of its internal `data`. This will also add a `rel8n` to the
  original ib_gib via the "past" rel8n.

  ## Implementation Details

  Internally, creating new ib_gib equates to bringing two ib_gib "into contact"
  with each other. Since all ib_gib are immutable, this ends up creating a
  "pure" functional programming style. So say you call fork on some ib_gib A,
  like so (I'm omitting some syntax for didactic purposes):

    `B = A |> fork(args)`

  This will take the state from A and the args and create a `plan^gib`
  descendant which will act as our function, with a plan^gib of something like
  "plan^ABC". The `IbGib.Expression.Supervisor` will then create a new
  child expression process that acts like a blank "stem-cell", and then it will
  call `IbGib.Expression.express/4` on that process, passing in A's ib^gib, A's
  state, B's ib^gib, and the identity/auth information of the caller.

  This blank process will then express by combining A with B. In this case,
  it will "apply" plan^ABC, in the process of doing so creating some fork,
  `fork^XYZ`, and apply that fork. When it is done, there will be a "new"
  ib_gib process with a state that is very similar to the original, but changed
  "dna" and "history" `rel8ns` (as well as identity changes). This state will
  be persisted to the repo as well and put into cache.

  Realistically in code, this is jumping through a bunch of hoops, which in
  general goes something like this:

  * Client API called, `fork`
  * `handle_call` for `:fork`
  * `fork_impl/4` called,
    * Builds the plan with the fork information
    * Saves the plan (but not the fork_gib yet)
  * `express/4` called
    * Creates a blank "stem cell" process.
  * `handle_call` for `:express` on blank process.
  * `express_impl/5` called
    * Concretizes plan, replacing any variables.
    * Creates and applies `fork` transform.
      * `apply_fork` called
  * Returns newly created process.

  ## Init Functions

  In the init stage, an expression either loads existing information from
  the `IbGib.Data.Repo` or `IbGib.Data.Cache`, or it does the work of two
  ib_gib coming into contact with each other (see the Apply Functions).

  Note that this is a little fuzzy to me since I've implemented the plan
  structure for more dynamic transform application. Init and apply are still
  used though.

  ## Apply Functions

  These functions are called within init functions on new expressions. Here,
  we take the first ib_gib info (`a`) as our "starting point", and then we
  "apply" `b`, which for starters are pretty much transforms: `fork`, `mut8`,
  and `rel8`. When applying a query, I am not sure how the `a` will come into
  play, but initially it will be pretty much ignored (I think).

  So these apply functions actually perform the "work" of combining two ib_gib,
  producing a new state in the form of a map.

  ## Note on Refactoring

  Some of these functions have been refactored out into their own modules.
  These include `IbGib.Expression.Apply`, `IbGib.Expression.PlanExpresser`,
  `IbGib.Expression.ExpressionHelper`.

  ## FAQ

  * Why do I keep quoting "new" as in creating a "new" ib_gib?

    "New" is a funny term. Each and every thing in existence can be thought of
    as both new and old, simultaneously, apart, etc. Because the ascription of
    the term is not a given. In a more concrete sense, if that's your thing,
    you can understand that when we bring two ib_gib into contact with each
    other to "create" a tertiary ib_gib, and if those two things have already
    been brought into contact before, then they will produce the same result.
    So it would not create a new thing, it would load an "existing" one. The
    `gib` hash relies on the `ib`, the `data`, and the `rel8ns`. When it goes
    to load it into the Repo, it will go "oops, I've already created this".

    Anyway, it's not a big thing. But me, personally, developing thing, it pops
    into my mind that they're not necessarily "new", and they're not necessarily
    being created, etc. (And they are. ibGib.)

  * What is the point of all of this?

    There are a lot of "points", i.e. many use cases. You can now think of IoT
    things, as this allows for a mechanism of relatinships and state to grow
    and evolve. You can share texts, streams of texts, streams of pictures,
    organizations of links. You can create reviews, you can share reviews. It's
    basically like a new-ish microcosm of the interweb, but being content
    addressable, shareable, identifiable.

    It allows for big data to happen in the foreground, as I call it: LITL Data
    (Live In The Light Data). This information is _already_ being collected
    about you. This is bringing it into the light, relying more on
    authentication than on encryption (but it will run on SSL).

    I personally have been doing gardening recently, and I've come to create
    photo albums of various sections of the gardens, etc. I can make superficial
    comments here and there, and I can send a link...but I can't **relate**
    things. I can't easily organize them. I can't take a photo and tag it with
    "help", and then have someone else who is searching to lend help adds their
    comments. I could then give feedback on the help. They could then give
    feedback on the feedback. **ALL** of it is in the Light!

    If consumers and/or businesses want to encapsulate their own internal
    functions for producing the data, that's fine. Anyone can read the data. But
    you have to identify yourself if you want to post new data, which cannot be
    removed (except for illegal content, flagged, etc.).

    And advertising and "blog" reviews takes on a whole new meaning. *Everyone*
    who uses products can share what they do and what products they use. You
    get to see how a product lasts over time, from the initial packaging to
    the consumer use. You could also publish **before** the product makes it to
    the consumer! You can publish your car getting worked on, and there is
    no need for some specialized software to do the fundamental publishing.
    You could still have specialized software to do the markup and presentation,
    but the general workflow would be for producers to produce things that are
    related to the consumers, to attribute relationships. Others can just go
    around and relate things to each other.

    So basically, it's like Amazon reviews + Twitter streams + Internet links +
    Git content addressing/hashing + Pinterest + interactive blogs +...
  """

  # Style warning: This module is waaay too big right now. It has been
  # a journey to simply produce the behavior as concisely as I can. Now that
  # the large bulk of it is complete, I am slowly refactoring. (just did authz)

  # ----------------------------------------------------------------------------
  # alias, import, require, use
  # ----------------------------------------------------------------------------

  require Logger
  use GenServer

  alias IbGib.Helper
  alias IbGib.Expression.{Apply, PlanExpresser}
  alias IbGib.Transform.Factory, as: TransformFactory
  alias IbGib.Transform.Plan.Factory, as: PlanFactory

  import IbGib.Macros

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  # ----------------------------------------------------------------------------
  # Constructors
  # ----------------------------------------------------------------------------

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
    _ = Logger.debug "{ib, gib}: {#{inspect ib}, #{inspect gib}}"
    GenServer.start_link(__MODULE__, {:ib_gib, {ib, gib}})
  end
  def start_link({:apply, {a, b}}) when is_map(a) and is_map(b) do
    # expr_id = Helper.new_id |> String.downcase
    _ = Logger.debug "a: {#{inspect a}\nb: #{inspect b}}"
    GenServer.start_link(__MODULE__, {:apply, {a, b}})
  end
  def start_link({:express, {identity_ib_gibs, a, a_info, b}})
    when is_bitstring(a) and (is_map(a_info) or is_nil(a_info)) and
         is_bitstring(b) do
    _ = Logger.debug "express. a: {#{a}\nb: #{b}}"
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
    register_result = IbGib.Expression.Registry.register(Helper.get_ib_gib!(ib, gib), self())
    if register_result == :ok do
      {:ok, :ok} = set_life_timeout(:load)
      {:ok, %{:info => info}}
    else
      _ = Logger.error "Register expression error: #{inspect register_result}"
      {:error, register_result}
    end
  end
  # Creating a "new" ib_gib from two existing ib_gib by "applying" b to a.
  # Currently, this is only used for applying a query. All other applies now
  # happen within the express process which uses plans.
  def init({:apply, {a, b}}) when is_map(a) and is_map(b) do
    Apply.apply_yo(a, b)
  end
  # Creating a "blank" ib_gib in preparation for expression of a and b.
  def init({:express, {identity_ib_gibs, a_ib_gib, _a_info, b_ib_gib}})
    when is_bitstring(a_ib_gib) and is_bitstring(b_ib_gib) do
    Logger.metadata([x: :express])
    _ = Logger.debug "express. identity_ib_gibs: #{inspect identity_ib_gibs}\na_ib_gib: #{a_ib_gib}\n, b_ib_gib: #{b_ib_gib}"

    {:ok, :ok} = set_life_timeout(:expression)

    # I don't think any state is required...but maybe the expressed flag would be good.
    state = %{}

    {:ok, state}
  end

  # These set basic life timeout limits on the ib_gib processes. Each process
  # is already persisted in the data store, so this is more of a caching
  # mechanism.
  # Queries are the least short lived, when they first get run. They will
  # be regenerated when they are rerun.
  # Next are expressions. They last a little longer.
  # Anything that is loaded from memory indicates something that the user is
  # reusing, so that lasts the longest.
  def set_life_timeout(:query) do
    _ = Logger.debug "setting life timeout for :query"
    set_life_timeout(:query, 300_000)
  end
  def set_life_timeout(:expression) do
    _ = Logger.debug "setting life timeout for :expression"
    set_life_timeout(:expression, 900_000)
  end
  def set_life_timeout(:load) do
    _ = Logger.debug "setting life timeout for :load"
    set_life_timeout(:load, 1_800_000)
  end
  def set_life_timeout(what, timeout_ms) do
    timeout_ms = timeout_ms + :rand.uniform(15_000)
    _ref = self() |> Process.send_after({:life_timeout, what}, timeout_ms)
    {:ok, :ok}
  end

  def handle_info({:life_timeout, what}, state) do
    _ = Logger.debug "timeout...stopping #{what} normally"
    {:stop, :normal, state}
  end

  # Note: Root maps to "ib". All of the others map to the string.
  defp init_default(:root), do: get_default("ib")
  defp init_default(:fork), do: get_default("fork")
  defp init_default(:mut8), do: get_default("mut8")
  defp init_default(:rel8), do: get_default("rel8")
  defp init_default(:query), do: get_default("query")

  # Builds the default ib_gib structure for "primitive"-like ib_gib.
  defp get_default(ib_string) when is_bitstring(ib_string) do
    _ = Logger.debug "initializing ib_gib #{ib_string} expression."
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
  # Christianity is NOT about dogma. It's about logic. Christ literally embodies
  # the living code of existence. I'm not being melodramatic here. I'm only
  # being precise.

  # ----------------------------------------------------------------------------
  # Express Implementation
  # ----------------------------------------------------------------------------

  @doc """
  Brings two ib_gib into contact with each other to produce a third, probably
  new, ib_gib.
  """
  def contact(this_pid, that_pid) when is_pid(this_pid) and is_pid(that_pid) do
    GenServer.call(this_pid, {:contact, that_pid})
  end

  # ----------------------------------------------------------------------------
  # Client API - Express
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

  Expression happens on the erlang "server" node, which should be a "blank"
  node that has just been started specifically for the purpose of being
  expressed.

  This gives us a couple benefits:
    1. All "processing" happens in parallel.
    2. Any errors are confined to the new server process.
    3. No database info is persisted unless the process expresses successfully.
  """
  def express(identity_ib_gibs, a_ib_gib, a_info, b_ib_gib)
  def express(_identity_ib_gibs, a_ib_gib, _a_info, @root_ib_gib) do
    # The @root_ib_gib (ib^gib) acts as an "identity" transform, so just return
    # the incoming ib^gib without touching the server.
    # NB: This bypasses adding anything to the dna.
    {:ok, a_ib_gib}
  end
  def express(identity_ib_gibs, a_ib_gib, a_info, b_ib_gib)
    when is_list(identity_ib_gibs) and is_bitstring(a_ib_gib) and
         is_map(a_info) and is_bitstring(b_ib_gib) do
    _ = Logger.debug "identity_ib_gibs:\n#{inspect identity_ib_gibs}\na_ib_gib: #{a_ib_gib}\na_info:\n#{inspect a_info, pretty: true}\nb_ib_gib: #{b_ib_gib}"
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
    _ = Logger.error emsg
    {:error, emsg}
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
    _ = Logger.error emsg
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

  See `IbGib.Transform.Mut8.Factory` for more details.
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
    _ = Logger.error emsg
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
  def rel8(expr_pid, other_pid, identity_ib_gibs, rel8ns,
           opts \\ @default_transform_options)
  def rel8(expr_pid, other_pid, identity_ib_gibs, rel8ns, opts)
    when is_pid(expr_pid) and is_pid(other_pid) and expr_pid !== other_pid and
         is_list(identity_ib_gibs) and length(identity_ib_gibs) >= 1 and
         is_list(rel8ns) and length(rel8ns) >= 1 and
         is_map(opts) do
    _ = Logger.debug "rel8 huh"
    GenServer.call(expr_pid, {:rel8, other_pid, identity_ib_gibs, rel8ns, opts})
  end
  def rel8(expr_pid, other_pid, identity_ib_gibs, rel8ns, opts) do
    emsg = emsg_invalid_args([
        expr_pid, other_pid, identity_ib_gibs, rel8ns, opts
      ])
    _ = Logger.error emsg
    {:error, emsg}
  end

  @doc """
  Bang version of `rel8/6`.
  """
  @spec rel8!(pid, pid, list(String.t), list(String.t), map) :: pid
  def rel8!(expr_pid, other_pid, identity_ib_gibs, rel8ns,
            opts \\ @default_transform_options) do
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
    _ = Logger.error(emsg)
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

  Returns the (tagged) pid of the new version of the given `expr_pid`.
  E.g. pid_a0 returns {:ok, pid_a1}
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
    _ = Logger.debug "bad opts: #{inspect opts}"
    GenServer.call(expr_pid, {:instance, identity_ib_gibs, dest_ib, %{}})
  end

  @doc """
  Bang version of `instance/4`.
  """
  @spec instance!(pid, list(String.t), String.t, map) :: pid | any
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
    _ = Logger.debug "bad opts: #{inspect opts}"
    bang(instance(expr_pid, identity_ib_gibs, dest_ib, %{}))
  end

  @doc """
  Executes the given `plan` using the `expr_pid` as the source ibGib.

  See `IbGib.Transform.Plan.Factory` for individual plans, and
  `IbGib.Transform.Plan.Builder` for how the plans are constructed.

  This is how I'm "planning" on going forward with commands from clients.
  Ideally I should have my validate plan logic here, but for now I am keeping
  the validation logic in the front-facing layer. This Expression will simply
  execute or fail in attempting to do so.
  """
  @spec execute_plan(pid, map) :: {:ok, pid} | {:error, any}
  def execute_plan(expr_pid, plan)
  def execute_plan(expr_pid, plan)
    when is_pid(expr_pid) and is_map(plan) do
    GenServer.call(expr_pid, {:execute_plan, plan})
  end
  def execute_plan(expr_pid, plan) do
    emsg = emsg_invalid_args([expr_pid, plan])
    _ = Logger.error emsg
    {:error, emsg}
  end

  @doc """
  Bang version of `execute_plan/2`.
  """
  @spec execute_plan!(pid, map) :: pid | any
  def execute_plan!(expr_pid, plan) do
    bang(execute_plan(expr_pid, plan))
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

  def handle_call({:express, {identity_ib_gibs, a_ib_gib, a_info, b_ib_gib}},
                  _from,
                  state) do
    {:ok, {new_ib_gib, new_state}} =
      PlanExpresser.express_plan(identity_ib_gibs, a_ib_gib, a_info, b_ib_gib, state)
    {:reply, {:ok, new_ib_gib}, new_state}
  end
  def handle_call({:contact, other_expr_pid}, _from, state) do
    {:reply, contact_impl(other_expr_pid, state), state}
  end
  def handle_call({:fork, identity_ib_gibs, dest_ib, opts}, _from, state) do
    {:reply, fork_impl(identity_ib_gibs, dest_ib, opts, state), state}
  end
  def handle_call({:mut8, identity_ib_gibs, new_data, opts}, _from, state) do
    {:reply, mut8_impl(identity_ib_gibs, new_data, opts, state), state}
  end
  def handle_call({:rel8, other_pid, identity_ib_gibs, rel8ns, opts}, _from, state) do
    {:reply, rel8_impl(other_pid, identity_ib_gibs, rel8ns, opts, state), state}
  end
  def handle_call({:instance_bootstrap, @bootstrap_identity_ib_gib, dest_ib, opts}, _from, state) do
    {:reply, instance_impl(@bootstrap_identity_ib_gib, dest_ib, opts, state), state}
  end
  def handle_call({:instance, identity_ib_gibs, dest_ib, opts}, _from, state) do
    {:reply, instance_impl(identity_ib_gibs, dest_ib, opts, state), state}
  end
  def handle_call({:execute_plan, plan}, _from, state) do
    {:reply, execute_plan_impl(plan, state), state}
  end
  def handle_call({:query, identity_ib_gibs, query_options}, _from, state) do
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
    _ = Logger.debug "state: #{inspect state}"

    with(
      # Gather info
      info <- state[:info],
      {ib, gib} <- {info[:ib], info[:gib]},
      {:ok, ib_gib} <- Helper.get_ib_gib(ib, gib),

      # Build the plan
      {:ok, plan} <- PlanFactory.fork(identity_ib_gibs, dest_ib, opts),

      # Save the plan
      {:ok, :ok} <- IbGib.Data.save(plan),
      {:ok, plan_ib_gib} <- Helper.get_ib_gib(plan),

      # Express (via spawned processes), passing only relevant ib^gib pointers.
      {:ok, new_ib_gib} <- express(identity_ib_gibs, ib_gib, info, plan_ib_gib),
      {:ok, new_pid} <- IbGib.Expression.Supervisor.start_expression(new_ib_gib)
    ) do
      {:ok, new_pid}
    else
      error -> Helper.default_handle_error(error)
    end
  end

  # ----------------------------------------------------------------------------
  # Server - mut8 impl
  # ----------------------------------------------------------------------------

  defp mut8_impl(identity_ib_gibs, new_data, opts, state) do
    _ = Logger.debug "state: #{inspect state}"

    with(
      # Gather info
      info <- state[:info],
      {ib, gib} <- {info[:ib], info[:gib]},
      {:ok, ib_gib} <- Helper.get_ib_gib(ib, gib),

      # Build the plan (_simple_ happy pipe would be awesome)
      {:ok, plan} <- PlanFactory.mut8(identity_ib_gibs, new_data, opts),

      # Save the plan
      {:ok, :ok} <- IbGib.Data.save(plan),
      {:ok, plan_ib_gib} <- Helper.get_ib_gib(plan),

      # Express (via spawned processes), passing only relevant ib^gib pointers.
      {:ok, new_ib_gib} <- express(identity_ib_gibs, ib_gib, info, plan_ib_gib),
      {:ok, new_pid} <- IbGib.Expression.Supervisor.start_expression(new_ib_gib)
    ) do
      {:ok, new_pid}
    else
      error -> Helper.default_handle_error(error)
    end
  end

  # ----------------------------------------------------------------------------
  # Server - rel8 impl
  # ----------------------------------------------------------------------------

  defp rel8_impl(other_pid, identity_ib_gibs, rel8ns, opts, state) do
    _ = Logger.debug "state: #{inspect state}"

    with(
      info <- state[:info],
      {ib, gib} <- {info[:ib], info[:gib]},
      {:ok, ib_gib} <- Helper.get_ib_gib(ib, gib),
      {:ok, other_info} <- IbGib.Expression.get_info(other_pid),
      {:ok, other_ib_gib} <-
        Helper.get_ib_gib(other_info[:ib], other_info[:gib]),

      # Build the plan
      {:ok, plan} <-
        PlanFactory.rel8(identity_ib_gibs, other_ib_gib, rel8ns, opts),

      # Save the plan
      {:ok, :ok} <- IbGib.Data.save(plan),
      {:ok, plan_ib_gib} <- Helper.get_ib_gib(plan),

      # Express (via spawned processes), passing only relevant ib^gib pointers.
      {:ok, new_ib_gib} <- express(identity_ib_gibs, ib_gib, info, plan_ib_gib),
      {:ok, new_pid} <- IbGib.Expression.Supervisor.start_expression(new_ib_gib)
    ) do
      {:ok, new_pid}
    else
      error -> Helper.default_handle_error(error)
    end
  end

  # ----------------------------------------------------------------------------
  # Server - instance impl
  # ----------------------------------------------------------------------------

  defp instance_impl(@bootstrap_identity_ib_gib, dest_ib, opts, state) do
    _ = Logger.debug "state: #{inspect state}"
    this_ib_gib = Helper.get_ib_gib!(state[:info])
    if this_ib_gib == @identity_ib_gib do
      _ = Logger.debug "instancing #{@identity_ib_gib}"
      instance_impl([@bootstrap_identity_ib_gib], dest_ib, opts, state)
    else
      {:error, emsg_only_instance_bootstrap_identity_from_identity_gib()}
    end
  end
  defp instance_impl(identity_ib_gibs, dest_ib, opts, state) do
    _ = Logger.debug "state: #{inspect state}"

    with(
      info <- state[:info],
      {ib, gib} <- {info[:ib], info[:gib]},
      {:ok, ib_gib} <- Helper.get_ib_gib(ib, gib),

      # Build the plan
      {:ok, plan} <- PlanFactory.instance(identity_ib_gibs, dest_ib, opts),

      # Save the plan
      {:ok, :ok} <- IbGib.Data.save(plan),
      {:ok, plan_ib_gib} <- Helper.get_ib_gib(plan),

      # Express (via spawned processes), passing only relevant ib^gib pointers.
      {:ok, new_ib_gib} <- express(identity_ib_gibs, ib_gib, info, plan_ib_gib),
      {:ok, new_pid} <- IbGib.Expression.Supervisor.start_expression(new_ib_gib)
    ) do
      {:ok, new_pid}
    else
      error -> Helper.default_handle_error(error)
    end
  end

  # ----------------------------------------------------------------------------
  # Server - execute_plan impl
  # ----------------------------------------------------------------------------

  defp execute_plan_impl(plan, state) do
    _ = Logger.debug "plan: #{inspect plan}\nstate: #{inspect state}"

    with(
      {:has_identities, identity_ib_gibs} when identity_ib_gibs != nil <-
        {:has_identities, plan[:data]["identities"]},
      info <- state[:info],
      {ib, gib} <- {info[:ib], info[:gib]},
      {:ok, ib_gib} <- Helper.get_ib_gib(ib, gib),

      # Save the plan
      {:ok, :ok} <- IbGib.Data.save(plan),
      {:ok, plan_ib_gib} <- Helper.get_ib_gib(plan),

      # Express (via spawned processes).
      {:ok, new_ib_gib} <- express(identity_ib_gibs, ib_gib, info, plan_ib_gib),
      {:ok, new_pid} <- IbGib.Expression.Supervisor.start_expression(new_ib_gib)
    ) do
      {:ok, new_pid}
    else
      {:has_identities, nil} -> {:error, "Plan contains no identities."}
      error -> Helper.default_handle_error(error)
    end
  end

  # ----------------------------------------------------------------------------
  # Server - query impl
  # ----------------------------------------------------------------------------

  defp query_impl(identity_ib_gibs, query_options, state)
    when is_map(query_options) do
    _ = Logger.debug "_state_: #{inspect state}"

    with(
      # 1. Create query ib_gib
      {:ok, query_info} <-
        TransformFactory.query(identity_ib_gibs, query_options),

      # 2. Save query ib_gib
      {:ok, :ok} <- IbGib.Data.save(query_info),

      # 3. Create instance process of query
      {:ok, query} <- IbGib.Expression.Supervisor.start_expression({query_info[:ib], query_info[:gib]}),

      # 4. Apply transform
      {:ok, new_pid} <- contact_impl(query, state)
    ) do
      # 5. Return new process of applied transform
      {:ok, new_pid}
    else
      error -> Helper.default_handle_error(error)
    end
  end

  defp contact_impl(other_pid, state) when is_pid(other_pid) and is_map(state) do
    _ = Logger.debug "state: #{inspect state}"
    _ = Logger.debug "other_expr_pid: #{inspect other_pid}"

    with(
      {:ok, other_info} <- get_info(other_pid),
      {:ok, new_pid} <-
        IbGib.Expression.Supervisor.start_expression({state[:info], other_info})
    ) do
      {:ok, new_pid}
    else
      error -> Helper.default_handle_error(error)
    end
  end
end
