defmodule WebGib.IbGibController do
  @moduledoc """
  Controller related to ib_gib code.
  """

  # ----------------------------------------------------------------------------
  # Usings, imports, etc.
  # ----------------------------------------------------------------------------

  use WebGib.Web, :controller

  alias IbGib.TransformFactory.Mut8Factory


  # ----------------------------------------------------------------------------
  # Controller Commands
  # ----------------------------------------------------------------------------

  @doc """
  This should show the "Home" ib^gib.
  """
  def index(conn, params) do
    Logger.warn "conn: #{inspect conn}"
    Logger.debug "index. params: #{inspect params}"


    conn
    |> assign(:ib, "ib")
    |> assign(:gib, "gib")
    |> assign(:ib_gib, @root_ib_gib)
    |> add_meta_query
    |> redirect(to: ib_gib_path(WebGib.Endpoint, :show, get_session(conn, @meta_query_result_ib_gib_key)))
    # |> redirect()
    # |> render("index.html")
  end

  defp add_meta_query(conn) do
    Logger.debug "meta_query_ib_gib: #{@meta_query_ib_gib_key}"
    Logger.debug "meta_query_result_ib_gib: #{@meta_query_result_ib_gib_key}"

    meta_query_ib_gib =
      conn |> get_session(@meta_query_ib_gib_key)
    meta_query_result_ib_gib =
      conn |> get_session(@meta_query_result_ib_gib_key)

    conn
    |> assign(:meta_query_ib_gib, meta_query_ib_gib)
    |> assign(:meta_query_result_ib_gib, meta_query_result_ib_gib)
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
          |> add_meta_query
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
      |> render("show.html")
    else
      error_msg = dgettext "error", "Hmmm...took a wrong turn somewhere :-/"
      Logger.error "#{error_msg}. (#{inspect result_term})"
      conn
      |> put_flash(:error, error_msg)
      |> redirect(to: "/ibgib")
    end
  end

  # ----------------------------------------------------------------------------
  # JSON Api
  # ----------------------------------------------------------------------------

  def get(conn, %{"ib_gib" => ib_gib} = params) do
    Logger.warn "mimicking latency....don't do this in production!"
    # Process.sleep(5000)
    Logger.debug "JSON get. conn: #{inspect conn}"
    Logger.debug "JSON get. params: #{inspect params}"
    with {:ok, pid} <- IbGib.Expression.Supervisor.start_expression(ib_gib),
      {:ok, info} <- pid |> IbGib.Expression.get_info do
      json(conn, info)
    else
      error -> json(conn, %{error: "#{inspect error}"})
    end
  end
  def get(conn, params) do
    Logger.debug "JSON get. conn: #{inspect conn}"
    Logger.debug "JSON get. params: #{inspect params}"
    Logger.error @emsg_invalid_ibgib_url
    json(conn, %{error: @emsg_invalid_ibgib_url})
  end

  def getd3(conn, %{"ib_gib" => ib_gib} = params) do
    Logger.warn "mimicking latency....don't do this in production!"
    # Process.sleep(5000)
    Logger.debug "JSON get. conn: #{inspect conn}"
    Logger.debug "JSON get. params: #{inspect params}"
    with {:ok, pid} <- IbGib.Expression.Supervisor.start_expression(ib_gib),
      {:ok, info} <- pid |> IbGib.Expression.get_info,
      {:ok, d3_info} <- convert_to_d3(info) do
      json(conn, d3_info)
    else
      error -> json(conn, %{error: "#{inspect error}"})
    end
  end
  def getd3(conn, params) do
    Logger.debug "JSON get. conn: #{inspect conn}"
    Logger.debug "JSON get. params: #{inspect params}"
    Logger.error @emsg_invalid_ibgib_url
    json(conn, %{error: @emsg_invalid_ibgib_url})
  end

  defp get_js_id(), do: "#{RandomGib.Get.some_letters(10)}"
  defp convert_to_d3(info) do
    ib_node_ibgib = get_ib_gib!(info)
    ib_gib_node = %{"id" => "ib#{@delim}gib", "name" => "ib", "cat" => "ibGib", "ibgib" => "ib#{@delim}gib", "js_id" => get_js_id}
    ib_node = %{"id" => ib_node_ibgib, "name" => info["ib"], "cat" => "ib", "ibgib" => ib_node_ibgib, "js_id" => get_js_id}

    nodes = [ib_gib_node, ib_node]

    links = []

    Logger.warn "info[:rel8ns]: #{inspect info[:rel8ns]}"
    {nodes, links} =
      Enum.reduce(info[:rel8ns],
                  {nodes, links},
                  fn({rel8n, rel8n_ibgibs}, {acc_nodes, acc_links}) ->

        # First get the node representing the rel8n itself.
        {group_node, group_link} = create_rel8n_group_node_and_link(rel8n, ib_node)

        # Now get the node and links for each ib^gib that belonds to that
        # rel8n.
        {item_nodes, item_links} = Enum.reduce(rel8n_ibgibs, {[],[]}, fn(r_ibgib, {acc2_nodes, acc2_links}) ->
          {item_node, item_link} = create_rel8n_item_node_and_link(r_ibgib, rel8n)
          {acc2_nodes ++ [item_node], acc2_links ++ [item_link]}
        end)

        # Return the accumulated {nodes, links}
        {
          acc_nodes ++ [group_node] ++ item_nodes,
          acc_links ++ [group_link] ++ item_links
        }
      end)

    {:ok, %{"nodes" => nodes, "links" => links}}
  end

  defp create_rel8n_group_node_and_link(rel8n, ib_node) do
    rel8n_node = %{"id" => rel8n, "name" => rel8n, "cat" => "rel8n", "js_id" => get_js_id}
    # {"source": "Champtercier", "target": "Myriel", "value": 1},
    rel8n_link = %{"source" => ib_node["id"], "target" => rel8n, "value" => 1}
    result = {rel8n_node, rel8n_link}
    Logger.debug "group node: #{inspect result}"
    result
  end

  defp create_rel8n_item_node_and_link(ibgib, rel8n) do
    {ib, _gib} = separate_ib_gib!(ibgib)
    item_node = %{"id" => "#{rel8n}: #{ibgib}", "name" => ib, "cat" => rel8n, "ibgib" => "#{ibgib}", "js_id" => get_js_id}
    item_link = %{"source" => rel8n, "target" => "#{rel8n}: #{ibgib}", "value" => 1}
    result = {item_node, item_link}
    Logger.debug "item node: #{inspect result}"
    result
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
      |> put_flash(:error, @emsg_invalid_dest_ib)
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
      |> put_flash(:error, @emsg_invalid_dest_ib)
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
    Logger.debug "dest_ib: #{dest_ib}"
    src =
      if src_ib_gib == "" or src_ib_gib == @root_ib_gib do
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
