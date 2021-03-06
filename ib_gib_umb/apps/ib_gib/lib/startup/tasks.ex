defmodule IbGib.Startup.Tasks do
  @moduledoc """
  These tasks are executed on each startup.
  """


# These methods were used with distillery post_start boot hook
# Thanks http://blog.firstiwaslike.com/elixir-deployments-with-distillery-running-ecto-migrations/
  # def migrate do
  #   {:ok, _} = Application.ensure_all_started(:ib_gib)
  #   ib_gib_mig_path = Application.app_dir(:ib_gib, "priv/repo/migrations")
  #   Ecto.Migrator.run(IbGib.Data.Repo, ib_gib_mig_path, :up, all: true)
  # end
  # def seed do
  #   ib_gib_repo_path = Application.app_dir(:ib_gib, "priv/repo")
  #   seed_path = Path.join(ib_gib_repo_path, "seeds.exs")
  #   Code.load_file(seed_path)
  # end


# These functions are used with each startup of application in `ib_gib.ex`.
# Thanks https://semaphoreci.com/community/tutorials/dockerizing-elixir-and-phoenix-applications

  @doc false
  def create_db do
    repo = IbGib.Data.Repo
    IO.puts "create_db #{inspect repo} started..."

    case repo.__adapter__.storage_up(repo.config()) do
      :ok ->
        IO.puts "The database for #{inspect repo} has been created."
      {:error, :already_up} ->
        IO.puts "The database for #{inspect repo} has already been created."
      {:error, reason} when is_binary(reason) ->
        IO.puts "The database for #{inspect repo} couldn't be created, reason given: #{reason}."
      {:error, reason} ->
        IO.puts "The database for #{inspect repo} couldn't be created, reason given: #{inspect reason}."
    end

    IO.puts "create_db #{inspect repo} complete."
  end

  @doc false
  def migrate_db do
    repo = IbGib.Data.Repo
    IO.puts "migrate_db #{inspect repo} started..."

    migrations_path =
      repo.config()
      |> Keyword.fetch!(:otp_app)
      |> Application.app_dir()
      |> Path.join("priv")
      |> Path.join("repo")
      |> Path.join("migrations")
    IO.puts "migrations path: #{inspect migrations_path}"
    Ecto.Migrator.run(repo, migrations_path, :up, [all: true])

    IO.puts "migrate_db #{inspect repo} complete."
  end

  @doc false
  def seed_db do
    repo = IbGib.Data.Repo
    IO.puts "seed_db #{inspect repo} starting..."

    :ib_gib
    |> Application.app_dir()
    |> Path.join("priv")
    |> Path.join("repo")
    |> Path.join("seeds.exs")
    |> Code.load_file

    IO.puts "seed_db #{inspect repo} complete."
  end
end
