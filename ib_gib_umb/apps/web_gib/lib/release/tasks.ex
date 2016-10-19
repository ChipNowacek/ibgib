defmodule WebGib.Release.Tasks do
  @moduledoc """
  Command for running ecto migrate on app startup.
  Thanks http://blog.firstiwaslike.com/elixir-deployments-with-distillery-running-ecto-migrations/

  """

  def migrate do
    # # migrate ibgib
    # {:ok, _} = Application.ensure_all_started(:ib_gib)
    # ib_gib_mig_path = Application.app_dir(:ib_gib, "priv/repo/migrations")
    # Ecto.Migrator.run(IbGib.Data.Repo, ib_gib_mig_path, :up, all: true)

    # seed ibgib
    # ib_gib_repo_path = Application.app_dir(:ib_gib, "priv/repo")
    # seed_path = Path.join(ib_gib_repo_path, "seeds.exs")
    # Code.load_file(seed_path)

    {:ok, _} = Application.ensure_all_started(:web_gib)
    web_gib_path = Application.app_dir(:web_gib, "priv/repo/migrations")
    Ecto.Migrator.run(WebGib.Data.Repo, web_gib_path, :up, all: true)
  end
end
