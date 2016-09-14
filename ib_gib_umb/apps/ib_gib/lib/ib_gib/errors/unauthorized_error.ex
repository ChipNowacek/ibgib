defmodule IbGib.Errors.UnauthorizedError do
  @moduledoc """
  Exception to raise when there is a problem with authorization (or lack
  thereof wah wah).
  """

  use IbGib.Constants, :error_msgs

  defexception [:message]

  def exception(expected_identity_ib_gibs, actual_identity_ib_gibs) do
    msg =
      emsg_invalid_authorization(expected_identity_ib_gibs,
                                 actual_identity_ib_gibs)
    %UnauthorizedError{message: msg}
  end
end
