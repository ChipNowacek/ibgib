defmodule WebGib.Errors.AuthenticationError do
  @moduledoc """
  Exception to raise when there is a problem with authentication.

  Plug knows how to handle this.
  Thanks! http://joshwlewis.com/essays/elixir-error-handling-with-plug/
  """

  use WebGib.Constants, :error_msgs

  defexception [message: @emsg_invalid_authentication, plug_status: 401]
end
