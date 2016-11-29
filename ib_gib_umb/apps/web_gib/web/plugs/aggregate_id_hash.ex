# defmodule WebGib.Plugs.AggregateIDHash do
#   @moduledoc """
#   Places an aggregate ID hash for the current user's identity/identities in
#   session.
#
#   This must come after the current user's identities are placed in session.
#   """
#
#   require Logger
#   import Plug.Conn
#   import Phoenix.Controller
#
#   import WebGib.Gettext
#   use WebGib.Constants, :keys
#   alias IbGib.Helper
#
#   @doc """
#   This options is created at "compile time" (when there is a request).
#   It is then passed to the `call/2` function, so whatever is returned here
#   will be used at runtime there.
#
#   Returns `:ok` by default.
#   """
#   def init(options) do
#     options
#   end
#
#   @doc """
#
#   """
#   def call(conn, options) do
#     _ = Logger.debug "put aggregate id hash into session yah"
#
#     with(
#       identity_ib_gibs <- conn |> get_session(@ib_identity_ib_gibs_key),
#       {:ok, agg_hash} <- Helper.get_aggregate_id_hash(identity_ib_gibs),
#       conn <- conn |> put_session(@ib_identity_agg_id_hash_key, agg_hash)
#     ) do
#       conn
#     else
#       error ->
#         _ = Logger.error "Error: #{inspect error}"
#         conn
#         |> put_flash(:error, gettext "There was a problem setting the aggregate id hash. :-/")
#         |> redirect(to: "/")
#         |> halt
#     end
#   end
# end
