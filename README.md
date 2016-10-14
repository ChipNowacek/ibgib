# ib_gib

Don't Panic.

![Current Screenshot of ibGib](/images/animated/2016-09-27-animated.gif)

## contributing, or just checking ib out

### issues and discussion

The best :fireworks: way to start contributing is just to start or join a
discussion. Start an issue, give it a question :question: or discussion :coffee:
label. Just **communicating** is a great contribution.

### up and running

If you want to dive into the code, here are some steps to get you up and
running.

Start off by forking the repo, clone and download the source. After this, you
will need to do a few things:  

1. Download and compile the dependencies.  
   * In the `ib_gib_umb` directory, run:
     * `mix deps.gets`
     * `mix deps.compile`  
   * In the `ib_gib_umb/apps/web_gib` directory, run:
     * `npm install`
2. Setup and run a PostgreSQL docker container for the repo(s).
   * [Docker must be installed.](https://docs.docker.com/engine/installation/)
   * Download the official `postgres` image.
     * `docker run --name postgres-ctr -e [POSTGRES_USER=postgres,POSTGRES_PASSWORD=postgres,POSTGRES_DB=ib_gib_db_dev] -d postgres`
   * You must be sure that this container is running whenever using the phoenix
     web server or tests.
3. Initialize Ecto for `ib_gib`.
   * Run the following commands in the `ib_gib_umb/apps/ib_gib/` folder:
     * `mix ecto.create`
     * `mix ecto.migrate`
   * Run the same commands in the `ib_gib_umb/apps/web_gib/` folder:
     * `mix ecto.create`
     * `mix ecto.migrate`

4. If you want to check out the POC web app, `web_gib`, you will need to run
   the phoenix web server, which once running, you should be able to point your browser to http://localhost/4000.
   * You may need to get a previous tag that is known to be compiling and
     working if you want to just check it out. I've just created
     [one right now](https://github.com/ibgib/ibgib/tree/tag-abstract-02-teething)
   * In the `web_gib` directory, run `mix phoenix.server` if you just want to
     run the server, or `iex -S mix phoenix.server` if you want to use observer
     to check out the processes while running the server with
     `iex> :observer.start`.
   * The address can be changed in `ib_gib_umb/apps/web_gib/config/config.exs`
   * The port can be changed in `ib_gib_umb/apps/web_gib/config/dev.exs`

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
