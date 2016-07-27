defmodule WebGib.Plugs.IbGibDefaults do
  require Logger
  import Plug.Conn

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
  Inject the root ib ("ib^gib") into conn assigns.
  """
  def call(conn, options) do
    Logger.debug "inspect options: #{inspect options}"
    {:ok, root} = IbGib.Expression.Supervisor.start_expression
    Logger.debug "assigning root in plug. root: #{inspect root}"
    assign(conn, :root, root)
  end
end
