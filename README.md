# Don't Panic.

www.ibgib.com

### Here, watch some videos...maybe up the speed to 2X.

[![Demo 01 - Login](https://github.com/ibgib/ibgib/blob/master/images/screenshots/03%20demo%20ibgib/demo01-login-screenshot.png)](https://youtu.be/rYUGE-bqR6s)
[![Demo 02 - Basics](https://github.com/ibgib/ibgib/blob/master/images/screenshots/03%20demo%20ibgib/demo02-basics-screenshot.png)](https://youtu.be/5qfoePRqLss)

## ibGib is ibGib
#### _(It's also a graph-ish, [merkle-ish](https://www.ibgib.com/ibgib/comment%5E2A35C15E95E108992A93CF80631D76B480DD62747C907DF19CE7899AF7FE3B08), database-ish, functional-language-ish engine, and a web app interfacing with that engine.)_

Right now, the ibGib's incarnation is basically two-fold: The ibGib web app and the ibGib engine that it uses.

## ibGib the Web App

The web app is a web-realtime application built with Phoenix (Elixir) using channels/sockets. The app's functionality is pretty "simple" at the moment, but still very powerful and useful. (I'm dogfooding it and I :heart: it.) 

Currently, here is the gist of it:

  * "Log in" via email magic link  
    * Additional security pin optional  
  * Create ibGib nodes  
    * "Folder-like" ibGib nodes that are intended for relationships among ibGib  
    * "File-like" ibGib nodes via comments (markdown), pics, and hyperlinks  
  * Query for ibGib
    * Via the `ib` (like folder/category names)
    * Via internal `data` properties (like words within comments)

## ibGib the Engine

The engine is created in Elixir (and the BEAM!), and it is all about creating, relating, and evolving immutable snapshots of ibGib in a monotonically increasing ibGib universe. Each datum has the following very "simple" structure: `ib`, `gib`, `rel8ns`, and `data`. 

The `ib` acts like the name of the ibGib. The `rel8ns` make it a graph-like structure, allowing for named relationships among all ibGib frames. The `data` contains the intrinsic content of the ibGib, similar to a file's contents. And the `gib` is a SHA-256 hash that verifies the integrity of the `ib`, `rel8ns`, and `data`.

So each ibGib frame is an immutable snapshot with an `ib^gib` URL that uniquely identifies that frame. Because of how the engine works, this effectively makes the `ib^gib` to act as reference pointers and the ibGib themselves act as pure functions: The same input will produce the same output.

## :point_up: Thank You :+1:

* [Elixir](http://elixir-lang.org/) & [Erlang](https://www.erlang.org/)
  * [Phoenix](http://www.phoenixframework.org/), [Ecto](https://github.com/elixir-ecto/ecto), [Postgrex](https://github.com/elixir-ecto/postgrex), [Distillery](https://github.com/bitwalker/distillery), [Poison](https://github.com/devinus/poison), [OK](https://github.com/CrowdHailer/OK), [ExDoc](https://github.com/elixir-lang/ex_doc), [Credo](https://github.com/rrrene/credo), [ExChalk](https://github.com/sotojuan/exchalk), [Dialyxir](https://github.com/jeremyjh/dialyxir), [Marker](https://github.com/zambal/marker), [Mailgun](https://github.com/chrismccord/mailgun), [Cowboy](https://github.com/ninenines/cowboy)
  * [Elixir on Slack](https://elixir-slackin.herokuapp.com/)
  * [ElixirForum](https://elixirforum.com/)
* JavaScript
  * [D3](https://d3js.org/)
  * [JQuery](https://jquery.com/)
* Data
  * [PostgreSQL](https://www.postgresql.org/)
* [Atom Code Editor](https://atom.io/)
  * [atom-elixir](https://github.com/msaraiva/atom-elixir), [autocomplete-elixir](https://github.com/wende/autocomplete-elixir), [language-elixir](https://github.com/elixir-lang/language-elixir), [linter-elixir-credo](https://github.com/smeevil/linter-elixir-credo)
* Deployment
  * [Docker](https://www.docker.com/)
    * [Engine](https://www.docker.com/products/docker-engine), [Compose](https://docs.docker.com/compose/), [Machine](https://docs.docker.com/machine/)
  * [AWS](https://aws.amazon.com/)
  * [NginX](https://www.nginx.com/)
* [GitHub](https://github.com/)
* [StackOverflow](https://stackoverflow.com/)
* [Atom]()
* (and more of course...)
* [ibGib](https://www.ibgib.com)


## contributing, or just checking ib out

### issues and discussion

The best :fireworks: way to start contributing is just to start or join a
discussion. Start an issue, give it a question :question: or discussion :coffee:
label. Just **communicating** is a great contribution.

### up and running

If you want to dive into the code, here are some steps to get you up and
running.

1. Fork this repo and clone it to your machine.
2. Download and compile the dependencies.  
   * In the `ib_gib_umb` directory, run:
     * `mix deps.gets`
     * `mix deps.compile`  
   * In the `ib_gib_umb/apps/web_gib` directory, run:
     * `npm install`
3. Setup and run a PostgreSQL docker container for the repo(s).
   * [Docker must be installed.](https://docs.docker.com/engine/installation/)
   * Download the official `postgres` image.
     * `docker run --name postgres-ctr -e [POSTGRES_USER=postgres,POSTGRES_PASSWORD=postgres,POSTGRES_DB=ib_gib_db_dev] -d postgres`
   * You must be sure that this container is running whenever using the phoenix
     web server or tests.
4. Initialize Ecto for `ib_gib`.
   * Run the following commands in the `ib_gib_umb/apps/ib_gib/` folder:
     * `mix ecto.create`
     * `mix ecto.migrate`
   * Run the same commands in the `ib_gib_umb/apps/web_gib/` folder:
     * `mix ecto.create`
     * `mix ecto.migrate`
5. To run `web_gib`, you will need to run the phoenix web server.
   * In `ib_gib_umb/apps/web_gib` folder...
     * Run `mix phoenix.server` to just run the server itself, which blocks and provides logging to the terminal. Or...
     * Run `iex -S mix phoenix.server` to run the server within iex.
       * This allows you to run `:observer.start()` which is pretty awesome.
       * Also, you can run other iex commands for your convenience.
   * Once running, point your browser to https://localhost:4443
   * You may need to get a previous tag that is known to be compiling.
     * [v0.1.0](https://github.com/ibgib/ibgib/tree/v0.1.0)
     * May be a newer version at [releases](https://github.com/ibgib/ibgib/releases).
   * The address can be changed in `ib_gib_umb/apps/web_gib/config/config.exs`
   * The port can be changed in `ib_gib_umb/apps/web_gib/config/dev.exs`
   * To get have email working, you will need to set up your own mailgun account
     and configure it in your own `dev.secret.exs`. (ping me @bill-mybiz if you
     want help with this).

### commit messages

I have a [`git-commit-template.txt`](https://github.com/ibgib/ibgib/blob/master/git-commit-template.txt) that I use when doing commits.

I would be very grateful :pray: if you would utilize this. If you are unfamiliar with
git commit templates...they're awesome! :fireworks: Just start a question issue
and I would be happy to explain what they are, how to use them (how I use
them anyway), etc.

That file is also where you can get the meaning of the commit emojis that I use.

### troubleshooting

* If you are getting a bunch of `Postgrex.Protocol` errors when starting the
  phoenix server, then perhaps you haven't started the PostgreSQL docker
  container.

### project structure

#### `ib_gib_umb`
Umbrella application for all Elixir-related ibGib apps.

#### `ib_gib`
Heart of the ibGib engine. Most of the meat right now is in
`lib/ib_gib/expression.ex`.

You can see how this is used in the tests in the `test/expression` directory
or in [`ib_gib_controller.ex`](https://github.com/ibgib/ibgib/blob/master/ib_gib_umb/apps/web_gib/web/controllers/ib_gib_controller.ex).

Keep in mind that the tests are starting the db from scratch. The "end" goal
(for this phase) is to bootstrap the "primitive types" such as numbers, strings,
arrays, etc., once the initial framework is up and running, although I do
[seed some primitives](https://github.com/ibgib/ibgib/blob/master/ib_gib_umb/apps/ib_gib/priv/repo/seeds.exs) for convenience. More on this later.

Here is my recommended order of perusing the test files, as well as a brief
description of each:

1. `data/data_test.exs`  
   * Just to give you an idea of how simple the one and only data construct
     that exists is.  
2. `expression/basics_test.exs`  
   * This builds up from first creating the root `ib_gib` process, then moving
     on to exercising the fundamental transforms: `fork`, `mut8`, and `rel8`.
3. `expression/hello_world_test.exs`  
   * These tests are where we start to build more complex constructs (`ib_gib`,
     or often just `ib`), i.e. exercising "Hello World" possibilities.
4. `expression/expression_query_test.exs`  
   * Tests for creating and executing queries against `ib_gib`.  
   * Queries are actually pretty neat, since each query is itself an `ib_gib`
     that creates a query result `ib_gib`. More on this later.  
5. `expression/extra_mut8_test.exs`  
   * Some additional `mut8` transforms that remove and rename keys in the
     `ib_gib`'s internal `:data` map.

The remaining tests are more structural to the Elixir app than anything
ibGib-specific.

#### `web_gib`
Phoenix application. Right now, this includes both "client" and "server".
This is very much a "simple" POC app to give an interface to the `ib_gib` app.

#### `random_gib`
Helper application that I created first when learning the basics of Elixir.
It provides some simple random functions.
