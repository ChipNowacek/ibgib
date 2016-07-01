defmodule IbGib do
  use Application

  def start(_type, _args) do
    IbGib.Supervisor.start_link
  end
end
