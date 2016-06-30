defmodule RandomGib do
  @moduledoc """
  Application that starts `RandomGib.Supervisor` which will host a
  `RandomGib.Get` worker process.
  """
  use Application
  # require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Logger.debug "RandomGib.Application start"
    children = [
      worker(RandomGib.Get, [RandomGib.Get])
    ]

    opts = [strategy: :one_for_one, name: RandomGib.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # def start(_type, _args) do
  #   import Supervisor.Spec, warn: false
  #
  #   children = [
  #     worker(RandomGib, [RandomGib])
  #   ]
  #
  #   opts = [strategy: :simple_one_for_one, name: RandomGib.Supervisor]
  #   Supervisor.start_link(children, opts)
  # end

end
