defmodule WebGib.Errors.IdentityError do
  @moduledoc """
  Exception to raise when there is a problem with session.

  Plug knows how to handle this.
  Thanks! http://joshwlewis.com/essays/elixir-error-handling-with-plug/
  """

  use WebGib.Constants, :error_msgs

  defexception [message: @emsg_invalid_identity, plug_status: 403]
end
