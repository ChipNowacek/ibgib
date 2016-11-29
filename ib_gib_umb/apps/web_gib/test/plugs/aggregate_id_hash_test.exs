defmodule WebGib.Test.Plugs.AggregateIDHashTest do
  @moduledoc """
  Test the `WebGib.Plugs.AggregateIDHash` plug which adds the current user's
  identity_ib_gibs hash to session.
  """
  require Logger

  use WebGib.ConnCase
  use WebGib.Constants, :keys

  setup context do
    Logger.disable(self)
    Code.load_file("../../apps/ib_gib/priv/repo/seeds.exs")
    Logger.enable(self)
  end

  @tag :capture_log
  test "GET /, home page doesn't get aggregate id hash injected", %{conn: conn} do
    _ = Logger.warn "plug test here. @ib_identity_agg_id_hash_key: #{@ib_identity_agg_id_hash_key}"
    conn = get conn, "/"

    _ = Logger.debug "wah wah wah"
    agg_id_hash = conn.get_session(@ib_identity_agg_id_hash_key)
    _ = Logger.debug "agg_id_hash: #{inspect agg_id_hash}"
    assert is_nil(agg_id_hash)
    # assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
