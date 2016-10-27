defmodule WebGib do
  @moduledoc """
  Application module for web_gib.
  """

  use Application

  import WebGib.Startup.Tasks

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    _ = create_db()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(WebGib.Data.Repo, []),
      # Start the endpoint when the application starts
      supervisor(WebGib.Endpoint, []),
      # Start your own worker by calling: WebGib.Worker.start_link(arg1, arg2, arg3)
      # worker(WebGib.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebGib.Supervisor]
    result = Supervisor.start_link(children, opts)

    _ = migrate_db()

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    WebGib.Endpoint.config_change(changed, removed)
    :ok
  end
end
