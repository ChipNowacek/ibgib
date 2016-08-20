defmodule WebGib.IbGibController do
  use WebGib.Web, :controller
  require Logger

  use IbGib.Constants, :ib_gib
  use WebGib.Constants, :error_msgs
  import IbGib.Helper
  alias IbGib.TransformFactory.Mut8Factory

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
        thing_relations = thing_info[:rel8ns]
        Logger.warn "thing_relations: #{inspect thing_relations}"
        conn =
          conn
          |> assign(:ib, ib)
          |> assign(:gib, gib)
          |> assign(:ib_gib, ib_gib)
          |> assign(:thing_data, thing_data)
          |> assign(:thing_relations, thing_relations)
          |> assign(:ancestors, thing_relations["ancestor"])
          |> assign(:past, thing_relations["past"])
        {:ok, conn}
    end

    if result == :ok do
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
  # Mut8
  # ----------------------------------------------------------------------------

  def mut8(conn, %{"mut8n" => %{"key" => key, "value" => value, "src_ib_gib" => src_ib_gib} = mut8n} = params) do
    Logger.debug "conn: #{inspect conn}"
    Logger.debug "conn.params: #{inspect conn.params}"
    Logger.debug "params: #{inspect params}"
    # data_key = conn.params["mut8n"]["key"]
    # data_value = conn.params["mut8n"]["value"]
    # data_key = params["mut8n"]["key"]
    # data_value = params["mut8n"]["value"]
    # msg = "key: #{data_key}.\nvalue: #{data_value}"
    msg = "key: #{key}\nvalue: #{value}"

    Logger.debug msg

    do_mut8(conn, src_ib_gib, {:add_update_key, key, value})
  end
  def mut8(conn, %{"mut8n" => %{"key" => key, "action" => action, "src_ib_gib" => src_ib_gib} = mut8n} = params) do
    Logger.debug "conn: #{inspect conn}"
    Logger.debug "conn.params: #{inspect conn.params}"
    Logger.debug "params: #{inspect params}"
    # data_key = conn.params["mut8n"]["key"]
    # data_value = conn.params["mut8n"]["value"]
    # data_key = params["mut8n"]["key"]
    # data_value = params["mut8n"]["value"]
    # msg = "key: #{data_key}.\nvalue: #{data_value}"
    msg = "key: #{key}\naction: #{action}"

    Logger.debug msg

    do_mut8(conn, src_ib_gib, {:remove_key, key})
  end

  defp do_mut8(conn, src_ib_gib, {:add_update_key, key, value}) do
    Logger.debug "."
    case mut8_impl(src_ib_gib, {:add_update_key, key, value}) do
      {:ok, mut8d_thing} ->
        Logger.info "mut8d_thing: #{inspect mut8d_thing}"

        mut8d_thing_info = mut8d_thing |> IbGib.Expression.get_info!
        ib = mut8d_thing_info[:ib]
        gib = mut8d_thing_info[:gib]
        ib_gib = get_ib_gib!(ib, gib)

        conn
        |> redirect(to: "/ibgib/#{ib_gib}")
      other ->
        # put flash error
        error_msg = dgettext "error", "Mut8 failed."
        Logger.error "#{error_msg}. (#{inspect other})"
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: "/ibgib/#{src_ib_gib}")
    end
  end
  defp do_mut8(conn, src_ib_gib, {:remove_key, key}) do
    Logger.debug "."
    case mut8_impl(src_ib_gib, {:remove_key, key}) do
      {:ok, mut8d_thing} ->
        Logger.info "mut8d_thing: #{inspect mut8d_thing}"

        mut8d_thing_info = mut8d_thing |> IbGib.Expression.get_info!
        ib = mut8d_thing_info[:ib]
        gib = mut8d_thing_info[:gib]
        ib_gib = get_ib_gib!(ib, gib)

        conn
        |> redirect(to: "/ibgib/#{ib_gib}")
      other ->
        # put flash error
        error_msg = dgettext "error", "Mut8 failed."
        Logger.error "#{error_msg}. (#{inspect other})"
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: "/ibgib/#{src_ib_gib}")
    end
  end

  defp mut8_impl(src_ib_gib, {:add_update_key, key, value})
      when is_bitstring(src_ib_gib) and
           is_bitstring(key) and is_bitstring(value) and
           src_ib_gib !== "" and key !== "" do
      Logger.debug "src_ib_gib: #{src_ib_gib}, key: #{key}, value: #{value}"

      {:ok, src} = IbGib.Expression.Supervisor.start_expression(src_ib_gib)
      src |> IbGib.Expression.mut8(Mut8Factory.add_or_update_key(key, value))
  end
  defp mut8_impl(src_ib_gib, {:remove_key, key})
      when is_bitstring(src_ib_gib) and
           is_bitstring(key) and
           src_ib_gib !== "" and key !== "" do
      Logger.debug "src_ib_gib: #{src_ib_gib}, key: #{key}"

      {:ok, src} = IbGib.Expression.Supervisor.start_expression(src_ib_gib)
      src |> IbGib.Expression.mut8(Mut8Factory.remove_key(key))
  end
  # ----------------------------------------------------------------------------
  # Fork
  # ----------------------------------------------------------------------------


  def fork(conn, %{"fork_form_data" => %{"dest_ib" => dest_ib, "src_ib_gib" => src_ib_gib}} = params) do
    Logger.debug "conn: #{inspect conn}"
    Logger.debug "conn.params: #{inspect conn.params}"
    Logger.debug "params: #{inspect params}"
    msg = "dest_ib: #{dest_ib}"

    if validate(:dest_ib, dest_ib) do
      do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib})
    else
      conn
      |> put_flash(:error, emsg_invalid_dest_ib)
      |> redirect(to: "/ibgib/#{src_ib_gib}")
    end
  end
  def fork(conn, %{"dest_ib" => dest_ib, "src_ib_gib" => src_ib_gib} = params) do
    Logger.debug "conn: #{inspect conn}"
    Logger.debug "conn.params: #{inspect conn.params}"
    Logger.debug "params: #{inspect params}"
    msg = "dest_ib: #{dest_ib}"

    if validate(:dest_ib, dest_ib) do
      do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib})
    else
      conn
      |> put_flash(:error, emsg_invalid_dest_ib)
      |> redirect(to: "/ibgib/#{src_ib_gib}")
    end
  end
  # def fork(conn, params) do
  #   Logger.warn "conn: #{inspect conn}"
  #   Logger.warn "conn.params: #{inspect conn.params}"
  #   Logger.warn "params: #{inspect params}"
  # end

  defp validate(:dest_ib, dest_ib) do
    valid_ib?(dest_ib) or
      # empty or nil dest_ib will be set automatically.
      dest_ib === "" or dest_ib === nil
  end
  # def fork(conn, %{"fork_form_data" => %{"dest_ib" => "", "src_ib_gib" => src_ib_gib}} = params) do
  #   dest_ib = ""
  #   Logger.debug "conn: #{inspect conn}"
  #   Logger.debug "conn.params: #{inspect conn.params}"
  #   Logger.debug "params: #{inspect params}"
  #   msg = "dest_ib: #{dest_ib}"
  #
  #   Logger.debug msg
  #
  #   do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib})
  # end
  # def fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib} = params) do
  #   Logger.debug "index. params: #{inspect params}"
  #   do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib})
  # end
  # def fork(conn, %{"src_ib_gib" => src_ib_gib} = params) do
  #   Logger.debug "index. params: #{inspect params}"
  #   do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => new_id})
  # end

  defp do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib}) do
    Logger.debug "src_ib_gib: #{src_ib_gib}\ndest_ib: #{dest_ib}"
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
         src_ib_gib !== "" and dest_ib !== "" do
    Logger.warn "dest_ib: #{dest_ib}"
    src =
      if (src_ib_gib == "") or (src_ib_gib == @root_ib_gib) do
        root
      else
        {:ok, thing} = IbGib.Expression.Supervisor.start_expression(src_ib_gib)
        thing
      end

    src |> IbGib.Expression.fork(dest_ib)
  end
  defp fork_impl(root, src_ib_gib, dest_ib)
    when is_bitstring(src_ib_gib) and is_bitstring(dest_ib) and
         src_ib_gib !== "" and (dest_ib === "" or is_nil(dest_ib)) do
      fork_impl(root, src_ib_gib, new_id)
  end
end
