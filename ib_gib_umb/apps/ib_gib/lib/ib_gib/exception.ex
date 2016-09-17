defmodule IbGib.UnauthorizedError do
  @moduledoc """
  Exception to raise when there is a problem with authorization (or lack
  thereof wah wah).

  Use with emsg_invalid_authorization(expected_identity_ib_gibs,
                                      actual_identity_ib_gibs)
  """

  defexception [:message]
end


defmodule IbGib.InvalidRel8Error do
  @moduledoc """
  Exception to raise when there is a problem with applying a rel8 transform.

  Use with emsg_invalid_rel8_src_mismatch(src_ib_gib, a_ib_gib)
  """

  defexception [:message]
end
