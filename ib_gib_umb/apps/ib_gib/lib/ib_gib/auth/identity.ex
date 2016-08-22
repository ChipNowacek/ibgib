defmodule IbGib.Auth.Identity do
  @moduledoc """
  This module relates to handling identity with respect to ib_gib.

  I am starting out with the following fundamental things:
    session^gib
    identity^gib
    email^gib

  Each of these will be instanced, mut8d and rel8d.

  For the session, I am using the ib as the hash of the session_id. So given
  a session id of `12345`, the actual session ib will be some large hash
  like `ABCDEFGHIJKLMNOSDFOIWEFHISDFJSDJFNDSF1234`. This way it is content-
  addressable and can be checked for easily. I don't plan on storing the
  session id itself.
  """

  use IbGib.Constants, :error_msgs
  import IbGib.{Expression, QueryOptionsFactory, Macros, Helper}

  require Logger

end
