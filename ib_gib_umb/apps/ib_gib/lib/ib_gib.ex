defmodule IbGib do
  @moduledoc """
  Application module for IbGib.
  """

  use Application

  import IbGib.Startup.Tasks

  def start(_type, _args) do
    IO.puts "Application IbGib start starting..."

    _ = create_db()

    result = IbGib.Supervisor.start_link

    _ = migrate_db()
    _ = seed_db()

    IO.puts "Application IbGib start complete."
    result
  end

end
