defmodule IbGib.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      # I don't like the structure of this. If the cache goes down,
      # it shouldn't affect the others. But the expression supervisor
      # and registry are tied to each other. rest for one doesn't quite
      # work either, and the registry doesn't seem to fit as a children
      # of the expression supervisor because it is a simple_one_for_one.
      # For now, not going to worry about it.
      supervisor(IbGib.Expression.Supervisor, []),
      supervisor(IbGib.Expression.Registry, []),
      supervisor(IbGib.Data.Cache, []),
      supervisor(IbGib.Data.Repo, [])
    ]

    supervise(children, strategy: :one_for_all)
  end
end
