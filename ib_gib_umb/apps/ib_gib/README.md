# IbGib

For abstract and heady conceptual material, read [ibgib's readme]().

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
process (obviously). We will need to create a fork transform instance that is
itself a fork of the root fork transform Thing. Once we create this transform,
we will need to have the expression express that it, thus applying the fork.

All of this sounds too much for a single test. So, we'll make some more unit-y
tests.
