defmodule WebGib.Plugs.IbGibRoot do
  @moduledoc """
  Injects the root ib into conn assigns.
  """

  require Logger
  import Plug.Conn

  use WebGib.Constants, :keys

  @doc """
  This options is created at "compile time" (when there is a request).
  It is then passed to the `call/2` function, so whatever is returned here
  will be used at runtime there.

  Returns `:ok` by default.
  """
  def init(options) do
    Logger.debug "inspect options: #{inspect options}"
    options
  end

  @doc """
  Inject the root ib_gib into conn assigns.
  """
  def call(conn, options) do
    {:ok, root} = IbGib.Expression.Supervisor.start_expression
    conn = assign(conn, :root, root)
    conn
  end
end
