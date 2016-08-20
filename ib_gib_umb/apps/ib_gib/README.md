# IbGib

For abstract and heady conceptual material, read [ibgib's readme](https://github.com/ibgib/ibgib/blob/master/README.md) or check out our
[wiki](https://github.com/ibgib/ibgib/wiki).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add ib_gib to your list of dependencies in `mix.exs`:

        def deps do
          [{:ib_gib, "~> 0.0.1"}]
        end

  2. Ensure ib_gib is started before your application:

        def application do
          [applications: [:ib_gib]]
        end


## hello world

I'm going to try to chronicle my own development of this latest incarnation,
moving very, very slowly to match how very, very hard it is to turn this very,
very abstract stuff into something very, very usable.

### starting tests

```
test "create expression, from scratch, root Thing" do
  flunk("not implemented")
end

test "create expression, from scratch, text Thing" do
  flunk("not implemented")
end

test "create expression, from scratch, text instance Thing" do
  flunk("not implemented")
end

test "create expression, from scratch, hello world Thing" do
  flunk("not implemented")
end

test "create expression, from scratch, hello world instance Thing with hello world text Thing" do
  flunk("not implemented")
end
```

* create expression = create a child process for the expression supervisor that
  uses a `:simple_one_for_one` strategy.
  * This means that no children are created when the supervisor is created, but
    rather they are created dynamically on demand.
* from scratch = create a child process with no incoming state.
  * This avoids (at least at the beginning)...
    * the plumbing of linking a supervisor factory "ctor" function
      (`start_child/link`) with the module function with the module's init
      function, etc.
    * the complexity of persistence of Things, Thing information/snapshots,
      transforms, etc.
  * We will add this kind of complexity stuck by stuck.
    * If you are new to ibgib, just ignore this avoids stuff. It's for me
      personally. I've been working on this complex stuff for a long time. Way
      too long.

### test 1 - app, expression, and supervisors

```
test "create expression, from scratch, root Thing" do
  flunk("not implemented")
end
```

To get a "root" Thing, really we just need to create a blank expression process.
This is because the root ib_gib is an implied Thing and it doesn't actually
require anything special beyond this (I don't think).

So we'll need an expression module and a supervisor to create its processes.
Doh, wait! We'll also need the actual IbGib Application and Supervisor as well.

Ah. Done. I've created [the `IbGib` Application module](lib/ib_gib.ex), its
[Supervisor](lib/ib_gib/supervisor.ex), the [IbGib.Expression](lib/ib_gib/expression.ex), and [its Supervisor](lib/ib_gib/expression/supervisor.ex).

This and a few tweaks gets our first test passing.

### test 2

```
test "create expression, from scratch, text Thing" do
  flunk("not implemented")
end
```

So this is where it gets interesting. We will need to first create a new
process. We will need to create a fork transform instance that is
itself a fork of the root fork transform Thing. Once we create this transform,
we will need to have the expression express that it, thus applying the fork.

All of this sounds too much for a single test. So, we'll need to break it down
a bit.

But first, a note on the overall design of the system: Everything, meaning
every "Thing", will be a process. For some simple transforms, like a bare fork
transform, this could conceivably be overkill. But transforms will need to be
managed insofar as caching is concerned when transforms with large sizes of
data are involved, like a possible image or video file.

With that in mind, let's write a test for creating a fork transform "instance",
i.e. a process.

```
test "create expression, from scratch, fork transform instance" do
  flunk("not implemented")
end
```

In order to create the fork transform instance, I've first created
[`IbGib.TransformFactory`](lib/ib_gib/transform_factory.ex) and added a
`fork/2` factory function. This function
accepts two arguments: `src_ib` and `dest_ib`. We use this if we
want to control the `ib` "id" of the Thing being "created" with the fork.
The "id" `ib` of the fork transform itself will be a hash using `dest_ib`..

However this only creates the map that contains the minimal fork transform
information, and it does not create the instance _process_.

To do that, we need the `Expression.Supervisor` to start the expression, but
as we have it right now, there is nothing tracking the pid of the expression.
What we need, or at least what I am working towards, is associating each
version of each Thing to its own process. This means that each process should
be an "immutable" process identified uniquely by its `ib` + `gib` fields.

This design has **extremely** interesting implications, but that returns us to
wacky conceptual abstractedness, so I'll leave it for another time. For now,
let's keep going with the mechanics.


## Pyramid of doom with branching case statement in the middle

def start_or_resume_session(session_id) when is_bitstring(session_id) do
  case IbGib.Expression.Supervisor.start_expression({"session", "gib"}) do
    {:ok, root_session} ->
      case get_session_ib(session_id) do
        {:ok, session_ib} ->
          case get_latest_session_ib_gib(session_id, root_session) do
            {:ok, nil} ->
              case (root_session |> instance(session_ib)) do
                {:ok, {_, session}} ->
                  case session |> get_info do
                    {:ok, session_info} ->
                      case get_ib_gib(session_info) do
                        {:ok, session_ib_gib} -> {:ok, session_ib_gib}
                        {:error, reason} -> {:error, reason}
                      end
                    {:error, reason} -> {:error, reason}
                  end
                {:error, reason} -> {:error, reason}
              end

            {:ok, existing_session_ib_gib} -> {:ok, existing_session_ib_gib}

            {:error, reason} -> {:error, reason}
          end
        {:error, reason} -> {:error, reason}
      end
    {:error, reason} -> {:error, reason}
  end
end

## Attempt with nesting `with` (doesn't compile)
def start_or_resume_session(session_id) when is_bitstring(session_id) do
  with {:ok, root_session} <- IbGib.Expression.Supervisor.start_expression({"session", "gib"}),
    {:ok, session_ib} <- get_session_ib(session_id),
    {:ok, session_ib_gib} <-
      case get_latest_session_ib_gib(session_id, root_session) do
        {:ok, nil} ->
          with {:ok, {_, session}} <- root_session |> instance(session_ib),
            {:ok, session_info} <- session |> get_info,
            {:ok, session_ib_gib} <- get_ib_gib(session_info) do
            {:ok, session_ib_gib}
          else
            {:error, reason} -> {:error, reason}
          end

        {:ok, existing_session_ib_gib} -> {:ok, existing_session_ib_gib}

        {:error, reason} -> {:error, reason}
      end,
      do: {:ok, session_ib_gib}
  else
    {:error, reason} -> {:error, reason}
  end
end

## Attempt with nesting `happy_path` (works, I think)
def start_or_resume_session(session_id) when is_bitstring(session_id) do
  happy_path do
    {:ok, root_session} = IbGib.Expression.Supervisor.start_expression({"session", "gib"})
    {:ok, session_ib} = get_session_ib(session_id)
    {:ok, existing_session_ib_gib} = get_latest_session_ib_gib(session_id, root_session)
    {:ok, session_ib_gib} =
      if (existing_session_ib_gib == nil) do
        Logger.debug "nil case...are we still on happy path?"
        # it's nil, so create a new one and return that
        # Are we still on the happy_path?  No. So nest another path?
        happy_path do
          {:ok, {_, session}} = root_session |> instance(session_ib)
          {:ok, session_info} = session |> get_info
          {:ok, session_ib_gib} = get_ib_gib(session_info)
          {:ok, session_ib_gib}
        end
      else
        {:ok, existing_session_ib_gib}
      end
    {:ok, session_ib_gib}
  end
end
