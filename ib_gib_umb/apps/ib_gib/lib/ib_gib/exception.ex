defmodule IbGib.UnauthorizedError do
  @moduledoc """
  Exception to raise when there is a problem with authorization (or lack
  thereof wah wah).

  Use with emsg_invalid_authorization(expected_identity_ib_gibs,
                                      actual_identity_ib_gibs)
  """

  defexception [:message]
end
