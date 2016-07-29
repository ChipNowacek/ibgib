defmodule WebGib.IbGibController do
  use WebGib.Web, :controller
  require Logger
  import IbGib.Helper

  @delim "^"
  @root_ib_gib "ib#{@delim}gib"

  # ----------------------------------------------------------------------------
  # Controller Commands
  # ----------------------------------------------------------------------------

  @doc """
  This should show the "Home" ib^gib.
  """
  def index(conn, params) do
    Logger.debug "index. params: #{inspect params}"
    # conn = init_session(conn)
    Logger.debug "root: #{inspect conn.assigns[:root]}"
    conn
    |> assign(:ib, "ib")
    |> assign(:gib, "gib")
    |> assign(:ib_gib, @root_ib_gib)
    |> render "index.html"
  end

  @doc """
  This should show the given `ib^gib`. If only the `ib` is given, then this
  should show what? The most "recent" `gib` hash?
  """
  def show(conn, %{"ib_or_ib_gib" => ib_or_ib_gib} = params) do
    as_list = ib_or_ib_gib |> String.split(@delim)
    ib = as_list |> Enum.at(0)
    gib = as_list |> Enum.at(1, "0")
    ib_gib = case get_ib_gib(ib, gib) do
      {:ok, res_ib_gib} -> res_ib_gib
      _ -> ib
    end

    {result, result_term} =
      with {:ok, thing} <- IbGib.Expression.Supervisor.start_expression({ib, gib}),
         {:ok, thing_info} <- thing |> IbGib.Expression.get_info do
        thing_data = thing_info[:data]
        thing_relations = thing_info[:relations]
        conn =
          conn
          |> assign(:ib, ib)
          |> assign(:gib, gib)
          |> assign(:ib_gib, ib_gib)
          |> assign(:thing_data, thing_data)
          |> assign(:thing_relations, thing_relations)
        {:ok, conn}
    end

    if (result === :ok) do
      conn = result_term
      conn
      |> render "show.html"
    else
      error_msg = dgettext "error", "Hmmm...took a wrong turn somewhere :-/"
      Logger.error "#{error_msg}. (#{inspect result_term})"
      conn
      |> put_flash(:error, error_msg)
      |> redirect(to: "/ibgib")
    end

  end


  # ----------------------------------------------------------------------------
  # Fork
  # ----------------------------------------------------------------------------

  def fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib} = params) do
    Logger.debug "index. params: #{inspect params}"
    do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib})
  end
  def fork(conn, %{"src_ib_gib" => src_ib_gib} = params) do
    Logger.debug "index. params: #{inspect params}"
    do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => new_id})
  end

  defp do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib}) do
    Logger.debug "."
    case fork_impl(conn.assigns[:root], src_ib_gib, dest_ib) do
      {:ok, forked_thing} ->
        Logger.info "forked_thing: #{inspect forked_thing}"

        forked_thing_info = forked_thing |> IbGib.Expression.get_info!
        ib = forked_thing_info[:ib]
        gib = forked_thing_info[:gib]
        ib_gib = get_ib_gib!(ib, gib)

        conn
        |> redirect(to: "/ibgib/#{ib_gib}")
      other ->
        # put flash error
        error_msg = dgettext "error", "Fork failed."
        Logger.error "#{error_msg}. (#{inspect other})"
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: "/ibgib")
    end
    # Logger.debug "doesn't exist huh: #{inspect get_session(conn, :never_put)}"

    # Logger.debug "start inspect conn"
    # Logger.info "#{inspect conn}"
    # Logger.debug "end inspect conn"

    # Logger.debug "old session message: #{inspect get_session(conn, :message)}"
    # conn = put_session(conn, :message, "session msg yo: #{new_id}")
    # Logger.debug "new session message: #{inspect get_session(conn, :message)}"
    # Logger.debug "session id: #{inspect get_session(conn, :id)}"
    # message = get_session(conn, :message)
    # text conn, message
  end

  defp fork_impl(root, src_ib_gib \\ @root_ib_gib, dest_ib \\ new_id)
  defp fork_impl(root, src_ib_gib, dest_ib)
    when is_bitstring(src_ib_gib) and is_bitstring(dest_ib) and
         src_ib_gib !== "" and src_ib_gib !== "" do
    Logger.debug "dest_ib: #{dest_ib}"
    src =
      if (src_ib_gib === "" or src_ib_gib === @root_ib_gib) do
        root
      else
        {:ok, thing} = IbGib.Expression.Supervisor.start_expression(src_ib_gib)
        thing
      end

    src |> IbGib.Expression.fork(dest_ib)
  end

end
