defmodule WebGib.IbGibController do
  @moduledoc """
  Controller related to ib_gib code.
  """

  # ----------------------------------------------------------------------------
  # Usings, imports, etc.
  # ----------------------------------------------------------------------------

  use WebGib.Web, :controller
  import Expat

  use IbGib.Constants, :validation
  use WebGib.Constants, :validation
  use WebGib.Constants, :config

  # alias IbGib.Transform.Mut8.Factory, as: Mut8Factory
  alias IbGib.{Expression, Auth.Identity}
  alias WebGib.Adjunct
  alias WebGib.Bus.Channels.Event, as: EventChannel
  import IbGib.QueryOptionsFactory
  import WebGib.{Patterns, Validate}

  # ----------------------------------------------------------------------------
  # Function Plugs
  # ----------------------------------------------------------------------------

  plug :authorize_upload when action in [:pic]

  # ----------------------------------------------------------------------------
  # Controller Commands
  # ----------------------------------------------------------------------------



  @doc """
  This should show the "Home" ib^gib.
  """
  def index(conn, params) do
    _ = Logger.debug "conn: #{inspect conn}"
    _ = Logger.debug "index. params: #{inspect params}"

    path_before_redirect = conn |> get_session(@path_before_redirect_key)
    prefix = "/ibgib/"
    {conn, target} =
      if path_before_redirect == nil or path_before_redirect == "" or !String.starts_with?(path_before_redirect |> URI.decode(), prefix) do
        {conn, @root_ib_gib}
      else
        target_ibgib = String.replace(path_before_redirect |> URI.decode(), prefix, "")
        Logger.debug("new target_ibgib: #{target_ibgib}" |> ExChalk.bg_blue)
        conn = conn |> put_session(@path_before_redirect_key, nil)
        {conn, target_ibgib}
      end

    conn
    |> assign(:ib, "ib")
    |> assign(:gib, "gib")
    |> assign(:ib_gib, target)
    # |> add_meta_query
    # |> redirect(to: ib_gib_path(WebGib.Endpoint, :show, get_session(conn, @meta_query_result_ib_gib_key)))
    |> redirect(to: ib_gib_path(WebGib.Endpoint, :show, target))
  end

  # defp add_meta_query(conn) do
  #   _ = Logger.debug "meta_query_ib_gib: #{@meta_query_ib_gib_key}"
  #   _ = Logger.debug "meta_query_result_ib_gib: #{@meta_query_result_ib_gib_key}"
  # 
  #   meta_query_ib_gib =
  #     conn |> get_session(@meta_query_ib_gib_key)
  #   meta_query_result_ib_gib =
  #     conn |> get_session(@meta_query_result_ib_gib_key)
  # 
  #   conn
  #   |> assign(:meta_query_ib_gib, meta_query_ib_gib)
  #   |> assign(:meta_query_result_ib_gib, meta_query_result_ib_gib)
  # end

  @doc """
  This should show the given `ib^gib`. If only the `ib` is given, then this
  should show what? The most "recent" `gib` hash?
  """
  def show(conn, %{"ib_or_ib_gib" => ib_or_ib_gib, "latest" => "true"} = _params) do
    ib_or_ib_gib =
      if valid_ib_gib?(ib_or_ib_gib), do: ib_or_ib_gib, else: @root_ib_gib

    if ib_or_ib_gib == @root_ib_gib do
      {conn, @root_ib_gib}
    else
      case get_latest_ib_gib(conn, ib_or_ib_gib) do
        {:ok, latest_ib_gib} ->
          conn
          |> redirect(to: "/ibgib/#{latest_ib_gib}")

        {:error, reason} ->
          emsg = "Could not get latest ib_gib. ib_or_ib_gib: #{ib_or_ib_gib}"
          _ = Logger.error("#{emsg}\n#{inspect reason}")
          conn
          |> put_flash(:error, gettext("Could not get the latest ibGib"))
          |> redirect(to: "/ibgib/#{@root_ib_gib}")
      end
    end
  end
  def show(conn, %{"ib_or_ib_gib" => ib_or_ib_gib} = _params) do
    ib_or_ib_gib =
      if valid_ib_gib?(ib_or_ib_gib), do: ib_or_ib_gib, else: @root_ib_gib

    as_list = ib_or_ib_gib |> String.split(@delim)
    ib = as_list |> Enum.at(0)
    gib = as_list |> Enum.at(1, "0")
    ib_gib = case get_ib_gib(ib, gib) do
      {:ok, res_ib_gib} -> res_ib_gib
      _ -> ib
    end

    {result, result_term} =
      with {:ok, thing} <- IbGib.Expression.Supervisor.start_expression({ib, gib}),
         {:ok, thing_info} <- thing |> Expression.get_info do
        thing_data = thing_info[:data]
        thing_relations = thing_info[:rel8ns]
        _ = Logger.debug "thing_relations: #{inspect thing_relations}"
        conn =
          conn
          # |> add_meta_query
          |> assign(:ib, ib)
          |> assign(:gib, gib)
          |> assign(:ib_gib, ib_gib)
          |> assign(:thing_data, thing_data)
          |> assign(:thing_relations, thing_relations)
          |> assign(:ancestors, thing_relations["ancestor"])
          |> assign(:past, thing_relations["past"])
          |> assign(:identity_ib_gibs, get_session(conn, @ib_identity_ib_gibs_key))
        {:ok, conn}
    end

    if result == :ok do
      _ = Logger.debug("conn:\n#{inspect conn}" |> ExChalk.black |> ExChalk.bg_yellow |> ExChalk.bold)
      conn = result_term
      conn
      |> render("show.html")
    else
      error_msg = dgettext "error", "Hmmm...took a wrong turn somewhere :-/"
      _ = Logger.error "#{error_msg}. (#{inspect result_term})"
      conn
      |> put_flash(:error, error_msg)
      |> redirect(to: "/ibgib/#{@root_ib_gib}")
    end
  end

  defp get_latest_ib_gib(conn, ib_gib) do
    _ = Logger.debug "ib_gib: #{ib_gib}"

    with(
      # Identities (need plug)
      identity_ib_gibs <- conn |> get_session(@ib_identity_ib_gibs_key),

      # We will query off of the current identity
      {:ok, src} <- IbGib.Expression.Supervisor.start_expression(Enum.at(identity_ib_gibs, 0)),

      # Our search for the latest version must be using the credentials of
      # **that** ibgib's identities, i.e. in that timeline.
      {:ok, ib_gib_process} <-
        IbGib.Expression.Supervisor.start_expression(ib_gib),
      {:ok, ib_gib_info} <- ib_gib_process |> Expression.get_info,
      {:ok, ib_gib_identity_ib_gibs} <-
        get_ib_gib_identity_ib_gibs(ib_gib_info),

      # Build the query options
      query_opts <- build_query_opts_latest(ib_gib_identity_ib_gibs, ib_gib),

      # Execute the query itself, which creates the query_result ib_gib
      {:ok, query_result} <-
        src |> Expression.query(identity_ib_gibs, query_opts),

        # Return the query_result result ib^gib
      {:ok, query_result_info} <- query_result |> Expression.get_info,
      {:ok, result_ib_gib} <- extract_result_ib_gib(ib_gib, query_result_info)
    ) do
      {:ok, result_ib_gib}
    else
      error -> default_handle_error(error)
    end
  end

  defp get_ib_gib_identity_ib_gibs(ib_gib_info) do
    _ = Logger.debug("ib_gib_info:\n#{inspect ib_gib_info}" |> ExChalk.magenta)
    rel8ns = ib_gib_info[:rel8ns]
    _ = Logger.debug("rel8ns:\n#{inspect rel8ns}" |> ExChalk.magenta)
    identities = rel8ns["identity"]
    _ = Logger.debug("identities:\n#{inspect identities}" |> ExChalk.magenta)
    {:ok, identities}
  end

  defp build_query_opts_latest(identity_ib_gibs, ib_gib) do
    query_identities = 
      identity_ib_gibs
      |> Enum.filter(&(&1 != @root_ib_gib))
      |> Enum.filter(fn(identity_ib_gib) -> 
           {ib, _gib} = separate_ib_gib!(identity_ib_gib)
           [type, _hash] = String.split(ib, "_")
           type !== "node" 
         end)

    do_query()
    |> where_rel8ns("identity", "withany", "ibgib", query_identities)
    |> where_rel8ns("past", "withany", "ibgib", [ib_gib])
    |> most_recent_only()
  end

  defp extract_result_ib_gib(src_ib_gib, query_result_info) do
    result_data = query_result_info[:rel8ns]["result"]
    result_count = Enum.count(result_data)
    case result_count do
      1 ->
        # Not found (1 result is root), so the "latest" is the one that we're
        # search off of (has no past)
        {:ok, src_ib_gib}

      2 ->
        # First is always root, so get second
        {:ok, Enum.at(result_data, 1)}

      _ ->
        _ = Logger.error "unknown result count: #{result_count}"
        {:ok, @root_ib_gib}
    end
  end

  # ----------------------------------------------------------------------------
  # JSON Api
  # ----------------------------------------------------------------------------

  # defpat ep_get_params(ep_ib_gib())

  def get(conn, ib_gib_(ib_gib: ib_gib) = params) do
  # def get(conn, %{"ib_gib" => ib_gib} = params) do
    # _ = Logger.warn "mimicking latency....don't do this in production!"
    # Process.sleep(RandomGib.Get.one_of([1500, 500, 1000, 2000]))
    _ = Logger.debug "JSON get. conn: #{inspect conn}"
    _ = Logger.debug "JSON get. params: #{inspect params}"
    with {:ok, pid} <- IbGib.Expression.Supervisor.start_expression(ib_gib),
      {:ok, info} <- pid |> Expression.get_info do
      json(conn, info)
    else
      error -> json(conn, %{error: "#{inspect error}"})
    end
  end
  def get(conn, params) do
    _ = Logger.debug "JSON get. conn: #{inspect conn}"
    _ = Logger.debug "JSON get. params: #{inspect params}"
    _ = Logger.error @emsg_invalid_ibgib_url
    json(conn, %{error: @emsg_invalid_ibgib_url})
  end


  @doc """
  Gets the ib_gib, it's ib, gib, data, and rel8ns in a format for consumption
  by the d3 engine.

  It duplicates the plain `get/2` call, but it's the best I got at the moment.
  """
  # def getd3(conn, ib_gib_(ib_gib: ib_gib) = params) do
  def getd3(conn, %{"ib_gib" => ib_gib} = params) do
    # _ = Logger.warn "mimicking latency....don't do this in production!"
    # Process.sleep(5000)
    _ = Logger.debug "JSON get. conn: #{inspect conn}"
    _ = Logger.debug "JSON get. params: #{inspect params}"
    with {:ok, pid} <- IbGib.Expression.Supervisor.start_expression(ib_gib),
      {:ok, info} <- pid |> Expression.get_info,
      {:ok, d3_info} <- convert_to_d3(info) do
      json(conn, d3_info)
    else
      error -> json(conn, %{error: "#{inspect error}"})
    end
  end
  def getd3(conn, params) do
    _ = Logger.debug "getd3. conn: #{inspect conn}\nparams: #{inspect params}"
    _ = Logger.error @emsg_invalid_ibgib_url
    json(conn, %{error: @emsg_invalid_ibgib_url})
  end

  # def get_image(conn, %{"binary_id" => binary_id} = params) do
  #   case IbGib.Data.load_binary(binary_id) do
  #
  #   end
  # end
  # def get_image(conn, params) do
  #   _ = Logger.debug "get_image. conn: #{inspect conn}\nparams: #{inspect params}"
  #   _ = Logger.error @emsg_invalid_ibgib_url
  #   json(conn, %{error: @emsg_invalid_ibgib_url})
  # end

  defp get_js_id(), do: "#{RandomGib.Get.some_letters(10)}"

  # Takes a given ib_gib `info` map and converts it to nodes and links for d3.
  # It creates a node for the ib_gib itself, the root ib^gib, and for each
  # rel8n and related ib_gib in each rel8n.
  # E.g. Say an ib_gib has 3 rel8ns as follows:
  #   "ancestor" => ["one^gib", "two^gib"]
  #   "dna" => ["three^gib", "four^gib"]
  #   "rel8d" => ["one^gib", "two^gib", "three^gib", "four^gib"]
  # Then this will create a node for the ib_gib itself, the root ib^gib, three
  # "rel8n" group nodes, and **eight** subnodes. It does not de-dupe the rel8d
  # ib_gib, as it shows each of these rel8d to their corresponding rel8n.
  defp convert_to_d3(info) do
    ib_node_ibgib = get_ib_gib!(info)
    {ib_node_ib, ib_node_gib} = separate_ib_gib!(ib_node_ibgib)
    ib_gib_node = %{"id" => "ib#{@delim}gib", "name" => "ib", "cat" => "ibGib", "ibgib" => "ib#{@delim}gib", "js_id" => get_js_id()}
    ib_node = %{"id" => ib_node_ibgib, "name" => ib_node_ib, "cat" => "ib", "ibgib" => ib_node_ibgib, "js_id" => get_js_id(), "ib" => ib_node_ib, "gib" => ib_node_gib, "render" => get_render(ib_node_ibgib, ib_node_ib, ib_node_gib)}

    nodes = [ib_gib_node, ib_node]

    links = []

    _ = Logger.debug "info[:rel8ns]: #{inspect info[:rel8ns]}"
    {nodes, links} =
      Enum.reduce(info[:rel8ns],
                  {nodes, links},
                  fn({rel8n, rel8n_ibgibs}, {acc_nodes, acc_links}) ->

        # First get the node representing the rel8n itself.
        {group_node, group_link} = create_rel8n_group_node_and_link(rel8n, ib_node)

        # Now get the node and links for each ib^gib that belongs to that
        # rel8n.
        {item_nodes, item_links, _prev_ib_gib} =
          rel8n_ibgibs
          |> Enum.reverse
          |> Enum.reduce({[],[], nil},
              fn(r_ibgib, {acc2_nodes, acc2_links, acc2_prev_ibgib}) ->
                {item_node, item_link} = create_rel8n_item_node_and_link(r_ibgib, rel8n, acc2_prev_ibgib)
                {
                  acc2_nodes ++ [item_node],
                  acc2_links ++ [item_link],
                  r_ibgib
                }
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
    rel8n_node = %{"id" => rel8n, "name" => rel8n, "cat" => "rel8n", "js_id" => get_js_id()}
    # {"source": "Champtercier", "target": "Myriel", "value": 1},
    rel8n_link = %{"source" => ib_node["id"], "target" => rel8n, "value" => 1}
    result = {rel8n_node, rel8n_link}
    _ = Logger.debug "group node: #{inspect result}"
    result
  end

  # These will relate to each other, not all to the group
  @linear_rel8ns ["past", "ancestor", "dna"]

  defp create_rel8n_item_node_and_link(ibgib, rel8n, prev_ibgib) do
    {ib, gib} = separate_ib_gib!(ibgib)
    item_node = %{
      "id" => "#{rel8n}: #{ibgib}",
      "name" => ib,
      "cat" => rel8n,
      "ibgib" => "#{ibgib}",
      "js_id" => get_js_id(),
      "ib" => ib,
      "gib" => gib,
      "render" => get_render(ibgib, ib, gib)
    }

    item_link =
      if rel8n in @linear_rel8ns and !is_nil(prev_ibgib) do
        # %{"source" => rel8n, "target" => "#{rel8n}: #{ibgib}", "value" => 1}
        %{"source" => "#{rel8n}: #{prev_ibgib}", "target" => "#{rel8n}: #{ibgib}", "value" => 1, "rel8n" => "#{rel8n}"}
      else
        %{"source" => rel8n, "target" => "#{rel8n}: #{ibgib}", "value" => 1, "rel8n" => "#{rel8n}"}
      end
    result = {item_node, item_link}
    _ = Logger.debug "item node: #{inspect result}"
    result
  end

  defp get_render(_ibgib, ib, _gib) do
    # (Very) Naive implementation to start with.
    case ib do
      "comment" -> "text"
      "pic" -> "image"
      "link" -> "text"
      _ -> "any"
    end
  end

  # ----------------------------------------------------------------------------
  # Mut8
  # ----------------------------------------------------------------------------

  # def mut8(conn, %{"mut8n" => %{"key" => key, "value" => value, "src_ib_gib" => src_ib_gib} = _mut8n} = params) do
  #   _ = Logger.debug "conn: #{inspect conn}"
  #   _ = Logger.debug "conn.params: #{inspect conn.params}"
  #   _ = Logger.debug "params: #{inspect params}"
  #   # data_key = conn.params["mut8n"]["key"]
  #   # data_value = conn.params["mut8n"]["value"]
  #   # data_key = params["mut8n"]["key"]
  #   # data_value = params["mut8n"]["value"]
  #   # msg = "key: #{data_key}.\nvalue: #{data_value}"
  #   msg = "key: #{key}\nvalue: #{value}"
  #
  #   _ = Logger.debug msg
  #
  #   do_mut8(conn, src_ib_gib, {:add_update_key, key, value})
  # end
  # def mut8(conn, %{"mut8n" => %{"key" => key, "action" => action, "src_ib_gib" => src_ib_gib} = _mut8n} = params) do
  #   _ = Logger.debug "conn: #{inspect conn}"
  #   _ = Logger.debug "conn.params: #{inspect conn.params}"
  #   _ = Logger.debug "params: #{inspect params}"
  #   # data_key = conn.params["mut8n"]["key"]
  #   # data_value = conn.params["mut8n"]["value"]
  #   # data_key = params["mut8n"]["key"]
  #   # data_value = params["mut8n"]["value"]
  #   # msg = "key: #{data_key}.\nvalue: #{data_value}"
  #   msg = "key: #{key}\naction: #{action}"
  #
  #   _ = Logger.debug msg
  #
  #   do_mut8(conn, src_ib_gib, {:remove_key, key})
  # end
  #
  # defp do_mut8(conn, src_ib_gib, {:add_update_key, key, value}) do
  #   _ = Logger.debug "."
  #   case mut8_impl(src_ib_gib, {:add_update_key, key, value}) do
  #     {:ok, mut8d_thing} ->
  #       Logger.info "mut8d_thing: #{inspect mut8d_thing}"
  #
  #       mut8d_thing_info = mut8d_thing |> Expression.get_info!
  #       ib = mut8d_thing_info[:ib]
  #       gib = mut8d_thing_info[:gib]
  #       ib_gib = get_ib_gib!(ib, gib)
  #
  #       conn
  #       |> redirect(to: "/ibgib/#{ib_gib}")
  #     other ->
  #       # put flash error
  #       error_msg = dgettext "error", "Mut8 failed."
  #       _ = Logger.error "#{error_msg}. (#{inspect other})"
  #       redirect_ib_gib =
  #         if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
  #       conn
  #       |> put_flash(:error, error_msg)
  #       |> redirect(to: "/ibgib/#{redirect_ib_gib}")
  #   end
  # end
  # defp do_mut8(conn, src_ib_gib, {:remove_key, key}) do
  #   _ = Logger.debug "."
  #   case mut8_impl(src_ib_gib, {:remove_key, key}) do
  #     {:ok, mut8d_thing} ->
  #       Logger.info "mut8d_thing: #{inspect mut8d_thing}"
  #
  #       mut8d_thing_info = mut8d_thing |> Expression.get_info!
  #       ib = mut8d_thing_info[:ib]
  #       gib = mut8d_thing_info[:gib]
  #       ib_gib = get_ib_gib!(ib, gib)
  #
  #       conn
  #       |> redirect(to: "/ibgib/#{ib_gib}")
  #     other ->
  #       redirect_ib_gib =
  #         if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
  #       # put flash error
  #       error_msg = dgettext "error", "Mut8 failed."
  #       _ = Logger.error "#{error_msg}. (#{inspect other})"
  #       conn
  #       |> put_flash(:error, error_msg)
  #       |> redirect(to: "/ibgib/#{redirect_ib_gib}")
  #   end
  # end
  #
  # defp mut8_impl(src_ib_gib, {:add_update_key, key, value})
  #     when is_bitstring(src_ib_gib) and
  #          is_bitstring(key) and is_bitstring(value) and
  #          src_ib_gib !== "" and key !== "" do
  #     _ = Logger.debug "src_ib_gib: #{src_ib_gib}, key: #{key}, value: #{value}"
  #
  #     {:ok, src} = IbGib.Expression.Supervisor.start_expression(src_ib_gib)
  #     src |> Expression.mut8(Mut8Factory.add_or_update_key(key, value))
  # end
  # defp mut8_impl(src_ib_gib, {:remove_key, key})
  #     when is_bitstring(src_ib_gib) and
  #          is_bitstring(key) and
  #          src_ib_gib !== "" and key !== "" do
  #     _ = Logger.debug "src_ib_gib: #{src_ib_gib}, key: #{key}"
  #
  #     {:ok, src} = IbGib.Expression.Supervisor.start_expression(src_ib_gib)
  #     src |> Expression.mut8(Mut8Factory.remove_key(key))
  # end

  # ----------------------------------------------------------------------------
  # Fork
  # ----------------------------------------------------------------------------

  defpat fork_form_data_(
    dest_ib_() = 
    src_ib_gib_()
  )
  
  def fork(conn, %{"fork_form_data" => fork_form_data_(...) = form_data} = params) 
    when is_nil(dest_ib) or dest_ib == "" do
    Logger.debug "whaaaaat. fork new something"
    dest_ib =
      if valid_ib_gib?(src_ib_gib) do
        {src_ib, _gib} = separate_ib_gib!(src_ib_gib)
        src_ib
      else
        new_id()
      end
    new_form_data = Map.put(form_data, "dest_ib", dest_ib)
    new_params = Map.put(params, "fork_form_data", new_form_data)
    fork(conn, new_params)
  end
  def fork(conn, %{"fork_form_data" => fork_form_data_(...) = form_data} = params) do
    _ = Logger.debug "conn: #{inspect conn}"
    _ = Logger.debug "conn.params: #{inspect conn.params}"
    _ = Logger.debug "abxparams: #{inspect params}"


    fork(conn, form_data)

    # if validate(:dest_ib, dest_ib) and validate(:ib_gib, src_ib_gib) do
    #   do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib})
    # else
    #   redirect_ib_gib =
    #     if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
    #   conn
    #   |> put_flash(:error, @emsg_invalid_dest_ib)
    #   |> redirect(to: "/ibgib/#{redirect_ib_gib}")
    # end
  end
  def fork(conn, dest_ib_(...) = src_ib_gib_(...) = _params) do
  # def fork(conn, %{"dest_ib" => dest_ib, "src_ib_gib" => src_ib_gib} = _params) do
    _ = Logger.debug "conn: #{inspect conn}"

    if validate(:dest_ib, dest_ib) and validate(:ib_gib, src_ib_gib) do
      do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib})
    else
      redirect_ib_gib =
        if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib

      conn
      |> put_flash(:error, @emsg_invalid_dest_ib)
      |> redirect(to: "/ibgib/#{redirect_ib_gib}")
    end
  end


  defp do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib}) do
    _ = Logger.debug "src_ib_gib: #{src_ib_gib}\ndest_ib: #{dest_ib}"
    case fork_impl(conn, conn.assigns[:root], src_ib_gib, dest_ib) do
      {:ok, forked_thing} ->
        Logger.info "forked_thing: #{inspect forked_thing}"

        forked_thing_info = forked_thing |> Expression.get_info!
        ib = forked_thing_info[:ib]
        gib = forked_thing_info[:gib]
        ib_gib = get_ib_gib!(ib, gib)

        conn
        |> redirect(to: "/ibgib/#{ib_gib}")
      other ->
        redirect_ib_gib =
          if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
        # put flash error
        error_msg = dgettext "error", "Fork failed."
        _ = Logger.error "#{error_msg}. (#{inspect other})"
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: "/ibgib/#{redirect_ib_gib}")
    end
  end

  defp fork_impl(conn, root, src_ib_gib, dest_ib)
  defp fork_impl(conn, root, src_ib_gib, dest_ib)
    when is_bitstring(src_ib_gib) and is_bitstring(dest_ib) and
         src_ib_gib !== "" and dest_ib !== "" do
    _ = Logger.debug "dest_ib: #{dest_ib}"
    src =
      if src_ib_gib == "" or src_ib_gib == @root_ib_gib do
        root
      else
        {:ok, thing} = IbGib.Expression.Supervisor.start_expression(src_ib_gib)
        thing
      end

    identity_ib_gibs = conn |> get_session(@ib_identity_ib_gibs_key)

    src
    |> Expression.fork(identity_ib_gibs, dest_ib, @default_transform_options)
  end
  defp fork_impl(conn, root, src_ib_gib, dest_ib)
    when is_bitstring(src_ib_gib) and is_bitstring(dest_ib) and
         src_ib_gib !== "" and (dest_ib === "" or is_nil(dest_ib)) do
      fork_impl(conn, root, src_ib_gib, new_id())
  end

  # ----------------------------------------------------------------------------
  # Comment
  # ----------------------------------------------------------------------------

  def comment(conn, %{"comment_form_data" => %{"comment_text" => comment_text, "src_ib_gib" => src_ib_gib}} = _params) do
    Logger.metadata(x: :comment_1)
    _ = Logger.debug "conn: #{inspect conn}"

    comment(conn, %{"comment_text" => comment_text, "src_ib_gib" => src_ib_gib})
  end
  def comment(conn, %{"comment_text" => comment_text, "src_ib_gib" => src_ib_gib} = _params) do
    Logger.metadata(x: :comment_2)
    _ = Logger.debug "conn: #{inspect conn}"
    _ = Logger.debug "@root_ib_gib: #{@root_ib_gib}"

    if validate(:comment_text, comment_text) and
                validate(:ib_gib, src_ib_gib) and
                src_ib_gib != @root_ib_gib do
      _ = Logger.debug "comment is valid. comment_text: #{comment_text}"

      case comment_impl(conn, src_ib_gib, comment_text) do
        {:ok, new_src_ib_gib} ->
          conn
          |> redirect(to: "/ibgib/#{new_src_ib_gib}")

        {:error, reason} ->
          redirect_ib_gib =
            if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
          _ = Logger.error reason
          friendly_emsg = dgettext "error", @emsg_invalid_comment
          conn
          |> put_flash(:error, friendly_emsg)
          |> redirect(to: "/ibgib/#{redirect_ib_gib}")
      end
    else
      redirect_ib_gib =
        if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
      _ = Logger.debug "comment is INVALID. comment_text: #{comment_text}"
      friendly_emsg = dgettext "error", @emsg_invalid_comment
      conn
      |> put_flash(:error, friendly_emsg)
      |> redirect(to: "/ibgib/#{redirect_ib_gib}")
    end
  end

  defp comment_impl(conn, src_ib_gib, comment_text) do
    _ = Logger.debug "src_ib_gib: #{src_ib_gib}\ncomment_text: #{comment_text}"

    with(
      identity_ib_gibs <- conn |> get_session(@ib_identity_ib_gibs_key),
      {:ok, src} <- IbGib.Expression.Supervisor.start_expression(src_ib_gib),
      {:ok, comment_gib} <-
        IbGib.Expression.Supervisor.start_expression("comment#{@delim}gib"),
      {:ok, comment} <-
        comment_gib
        |> Expression.fork(identity_ib_gibs,
                           "comment"),
      {:ok, comment} <-
        comment
        |> Expression.mut8(identity_ib_gibs, %{"text" => comment_text}),
      {:ok, new_src} <-
        src
        |> Expression.rel8(comment, identity_ib_gibs, ["comment"]),
      {:ok, new_src_info} <- new_src |> Expression.get_info,
      {:ok, new_src_ib_gib} <- get_ib_gib(new_src_info)
    ) do
      {:ok, new_src_ib_gib}
    else
      {:error, reason} when is_bitstring(reason) -> {:error, reason}
      {:error, reason} -> {:error, inspect reason}
      error -> {:error, inspect error}
    end
  end

  # ----------------------------------------------------------------------------
  # Pic
  # ----------------------------------------------------------------------------

  def pic(conn, %{"pic_form_data" => %{"pic_data" => pic_data, "src_ib_gib" => src_ib_gib}} = _params) do
    Logger.metadata(x: :pic_1)
    _ = Logger.debug "conn: #{inspect conn}"

    pic(conn, %{"pic_data" => pic_data, "src_ib_gib" => src_ib_gib})
  end
  def pic(conn,
          %{"pic_data" =>
            %Plug.Upload{
              content_type: content_type,
              filename: filename,
              path: path
            } = pic_data,
            "src_ib_gib" => src_ib_gib} = _params) do
    Logger.metadata(x: :pic_2)
    _ = Logger.debug "conn: #{inspect conn}"
    _ = Logger.debug "pic_data: #{inspect pic_data}"

    if validate(:pic_data, {content_type, filename, path}) and
       validate(:ib_gib, src_ib_gib) and
       src_ib_gib != @root_ib_gib do
      _ = Logger.debug "pic is valid. content_type, filename, path: #{content_type}, #{filename}, #{path}"

      case pic_impl(conn, src_ib_gib, content_type, filename, path) do
        {:ok, pic_ib_gib} ->
          conn
          |> send_resp(200, pic_ib_gib)
          |> halt()
          # |> redirect(to: "/ibgib/#{new_src_ib_gib}")

        {:error, reason} ->
          emsg = "There was an error uploading the pic. Error: #{inspect reason}"
          _ = Logger.error(emsg)
          conn
          |> send_resp(500, emsg)
      end
    else
      emsg = "Pic is invalid. pic_data: #{inspect pic_data}."
      _ = Logger.error(emsg)
      conn
      |> send_resp(500, emsg)
    end
  end

  defp pic_impl(conn, src_ib_gib, content_type, filename, path) do
    _ = Logger.debug "src_ib_gib: #{src_ib_gib}\ncontent_type, filename, path: #{content_type}, #{filename}, #{path}"
    with(
      # Prepare
      {:ok, {identity_ib_gibs, latest_src, pic_gib}} <-
        prepare_pic(conn, src_ib_gib),

      # Creates thumbnail, generates bin_ids to reference in pic_gib data.
      {:ok, {bin_id, thumb_bin_id, thumb_filename, ext}} <- save_pic_to_bin_store(conn, content_type, path, filename),

      {:ok, pic} <- create_pic(identity_ib_gibs,
                               latest_src,
                               pic_gib,
                               {content_type,
                                filename,
                                bin_id,
                                ext,
                                thumb_bin_id,
                                thumb_filename}),

      # If authorized, rel8 the pic directly to the src
      # (If the owner of the src is the one adding the pic)
      {:ok, new_src_or_nil} <-
          Adjunct.rel8_target_to_other_if_authorized(
            latest_src,
            pic,
            identity_ib_gibs,
            ["pic"]
          ),
      # If above is not authorized (new_src_or_nil is nil), then create
      # a 1-way adjunct rel8n on the comment to the src.
      {:ok, {pic, src_temp_junc_ib_gib_or_nil}} <-
        rel8_adjunct_if_necessary(new_src_or_nil, identity_ib_gibs, latest_src, pic),

      {:ok, {pic_ib_gib, new_src_ib_gib_or_nil}} <-
        get_ib_gibs_pic(pic, new_src_or_nil),

      # Broadcast updates, depending on if we have directly rel8d to
      # the src or if we rel8d an adjunct indirectly to it.
      {:ok, :ok} <-
        broadcast_pic(src_ib_gib,
                      pic_ib_gib,
                      new_src_ib_gib_or_nil,
                      src_temp_junc_ib_gib_or_nil)

    ) do
      {:ok, pic_ib_gib}
    else
      error -> default_handle_error(error)
    end
  end

  defp prepare_pic(conn, src_ib_gib) do
    with(
      identity_ib_gibs <- conn |> get_session(@ib_identity_ib_gibs_key),

      {:ok, latest_src_ib_gib} <-
        IbGib.Common.get_latest_ib_gib(identity_ib_gibs, src_ib_gib),
      {:ok, latest_src} <-
        IbGib.Expression.Supervisor.start_expression(latest_src_ib_gib),
      {:ok, pic_gib} <-
        IbGib.Expression.Supervisor.start_expression("pic#{@delim}gib")
    ) do
      {:ok, {identity_ib_gibs, latest_src, pic_gib}}
    else
      error -> default_handle_error(error)
    end
  end

  defp save_pic_to_bin_store(_conn, _content_type, path, filename) do
    _ = Logger.debug "saving..."
    with(
      # Get Binary id (hash of binary data)
      {:ok, body} <- File.read(path),
      binary_data <- IO.iodata_to_binary(body),
      binary_id <- hash(binary_data),

      # Create the target path full path+name+ext
      {:ok, :ok} <- ensure_path_exists(@upload_files_path),
      ext <- Path.extname(filename),
      target_full_path <-
        Path.join(@upload_files_path, binary_id <> ext),

      # Copy the file
      :ok <- File.cp(path, target_full_path),

      # Generate and save associated thumbnail
      tmp_thumb_full_path <- Path.join(@upload_files_path, new_id() <> ext),
      {"", 0} <- System.cmd("convert", [path, "-resize", @pic_thumb_size, tmp_thumb_full_path]),
      {:ok, thumb_body} <- File.read(tmp_thumb_full_path),
      thumb_binary_data <- IO.iodata_to_binary(thumb_body),
      thumb_binary_id <- hash(thumb_binary_data),
      thumb_filename <- @pic_thumb_filename_prefix <> thumb_binary_id ,
      thumb_target_full_path <-
        Path.join(@upload_files_path, thumb_filename <> ext),
      :ok <- File.rename(tmp_thumb_full_path, thumb_target_full_path)
    ) do
      _ = Logger.debug "saved."
      {:ok, {binary_id, thumb_binary_id, thumb_filename, ext}}
    else
      {"", thumb_error} ->
        _ = Logger.error(inspect thumb_error)
        emsg = @emsg_could_not_create_thumbnail
        default_handle_error({:error, emsg})

      error -> default_handle_error(error)
    end
  end

  defp create_pic(identity_ib_gibs, latest_src, pic_gib, {content_type, filename, bin_id, ext, thumb_bin_id, thumb_filename}) do
    with(
      # Generate pic ibGib
      # Need to convert this to a plan^gib
      {:ok, pic} <- pic_gib |> Expression.fork(identity_ib_gibs, "pic"),
      {:ok, pic} <-
        pic
        |> Expression.mut8(identity_ib_gibs,
                           %{
                             "content_type" => content_type,
                             "filename" => filename,
                             "bin_id" => bin_id,
                             "ext" => ext,
                             "thumb_bin_id" => thumb_bin_id,
                             "thumb_filename" => thumb_filename,
                             "thumb_size" => "#{@pic_thumb_size}",
                             "when" => get_timestamp_str()
                            }),
      {:ok, pic} <-
        pic |> Expression.rel8(latest_src, identity_ib_gibs, ["pic_"])
    ) do
      {:ok, pic}
    else
      error -> default_handle_error(error)
    end
  end

  defp rel8_adjunct_if_necessary(nil, identity_ib_gibs, latest_src, pic) do
    _ = Logger.debug("rel8_adjunct necessary. new_src is nil." |> ExChalk.bg_cyan |> ExChalk.black)
    # adjunct IS needed, because new_src is nil. The reasoning here is
    #   that we don't have a new_src (it's nil), so the user was NOT
    #   authorized to rel8 **directly** to the target, so we need an
    #   _adjunct_ rel8n.
    Adjunct.rel8_adjunct_to_target(
      latest_src,        # target
      pic,               # adjunct
      identity_ib_gibs,  # identity_ib_gibs
      "pic_",            # adjunct_rel8n
      "pic"              # adjunct_target_rel8n
    )
  end
  defp rel8_adjunct_if_necessary(_new_src, _identity_ib_gibs, _src, adjunct) do
    _ = Logger.debug("rel8_adjunct NOT necessary. new_src is NOT nil." |> ExChalk.bg_cyan |> ExChalk.black)
    # adjunct not needed, because new_src was not nil. The reasoning
    #   here is that we have a new_src only if we were authorized to
    #   rel8 adjunct to src **directly**, so we do NOT need an _adjunct_
    #   rel8n.
    {:ok, {adjunct, nil}}
  end

  defp get_ib_gibs_pic(pic, new_src) do
    with(
      {:ok, pic_info} <- Expression.get_info(pic),
      {:ok, pic_ib_gib} <- get_ib_gib(pic_info),

      {:ok, new_src_info} <-
        (if new_src, do: Expression.get_info(new_src), else: {:ok, nil}),
      {:ok, new_src_ib_gib} <-
        (if new_src, do: get_ib_gib(new_src_info), else: {:ok, nil})
    ) do
      {:ok, {pic_ib_gib, new_src_ib_gib}}
    else
      error -> default_handle_error(error)
    end
  end

  defp broadcast_pic(src_ib_gib,
                     pic_ib_gib,
                     new_src_ib_gib_or_nil,
                     src_temp_junc_ib_gib_or_nil)
  defp broadcast_pic(src_ib_gib,
                     _pic_ib_gib,
                     new_src_ib_gib,
                     nil) do
    # We directly rel8d the pic to the src, so publish an update
    # msg for the src only.
    EventChannel.broadcast_ib_gib_event(:update,
                                        {src_ib_gib, new_src_ib_gib})
    {:ok, :ok}
  end
  defp broadcast_pic(src_ib_gib,
                     pic_ib_gib,
                     nil = _new_src_ib_gib_or_nil,
                     src_temp_junc_ib_gib) do
    _ = Logger.debug("broadcasting :new_adjunct.\nsrc_temp_junc_ib_gib: #{src_temp_junc_ib_gib}\npic_ib_gib: #{pic_ib_gib}\nsrc_ib_gib: #{src_ib_gib}")
    EventChannel.broadcast_ib_gib_event(:new_adjunct,
                                        {src_temp_junc_ib_gib,
                                         pic_ib_gib,
                                         src_ib_gib})
    {:ok, :ok}
  end

  # @upload_files_path "/var/www/web_gib/files/"
  defp ensure_path_exists(@upload_files_path) do
    path = @upload_files_path
    if File.exists?(path) do
      _ = Logger.debug "File exists: #{path}"
      {:ok, :ok}
    else
      _ = Logger.debug "File does not exist: #{path}"
      case File.mkdir_p(path) do
        :ok -> {:ok, :ok}
        {:error, reason} ->
          _ = Logger.error "Could not mkdir_p(#{path}). reason: #{inspect reason}"
          {:error, reason}
      end
    end
  end
  # ----------------------------------------------------------------------------
  # Link
  # ----------------------------------------------------------------------------

  def link(conn, %{"link_form_data" => %{"link_text" => link_text, "src_ib_gib" => src_ib_gib}} = _params) do
    Logger.metadata(x: :link_1)
    _ = Logger.debug "conn: #{inspect conn}"

    link(conn, %{"link_text" => link_text, "src_ib_gib" => src_ib_gib})
  end
  def link(conn, %{"link_text" => link_text, "src_ib_gib" => src_ib_gib} = _params) do
    Logger.metadata(x: :link_2)
    _ = Logger.debug "conn: #{inspect conn}"
    _ = Logger.debug "@root_ib_gib: #{@root_ib_gib}"

    link_text =
      if String.starts_with?(link_text, "http") do
        link_text
      else
        "https://" <> link_text
      end

    if validate(:link_text, link_text) and
                validate(:ib_gib, src_ib_gib) and
                src_ib_gib != @root_ib_gib do
      _ = Logger.debug "link is valid. link_text: #{link_text}"

      case link_impl(conn, src_ib_gib, link_text) do
        {:ok, new_src_ib_gib} ->
          conn
          |> redirect(to: "/ibgib/#{new_src_ib_gib}")

        {:error, reason} ->
          redirect_ib_gib =
            if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
          _ = Logger.error reason
          friendly_emsg = dgettext "error", @emsg_invalid_link
          conn
          |> put_flash(:error, friendly_emsg)
          |> redirect(to: "/ibgib/#{redirect_ib_gib}")
      end
    else
      redirect_ib_gib =
        if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
      _ = Logger.debug "link is INVALID. link_text: #{link_text}"
      friendly_emsg = dgettext "error", @emsg_invalid_link
      conn
      |> put_flash(:error, friendly_emsg)
      |> redirect(to: "/ibgib/#{redirect_ib_gib}")
    end
  end

  defp link_impl(conn, src_ib_gib, link_text) do
    _ = Logger.debug "src_ib_gib: #{src_ib_gib}\nlink_text: #{link_text}"

    with(
      identity_ib_gibs <- conn |> get_session(@ib_identity_ib_gibs_key),
      {:ok, src} <- IbGib.Expression.Supervisor.start_expression(src_ib_gib),
      {:ok, link_gib} <-
        IbGib.Expression.Supervisor.start_expression("link#{@delim}gib"),
      {:ok, link} <-
        link_gib
        |> Expression.instance(identity_ib_gibs, "link"),
      {:ok, link} <-
        link
        |> Expression.mut8(identity_ib_gibs, %{"text" => link_text}),
      {:ok, new_src} <-
        src
        |> Expression.rel8(link, identity_ib_gibs, ["link"]),
      {:ok, new_src_info} <- new_src |> Expression.get_info,
      {:ok, new_src_ib_gib} <- get_ib_gib(new_src_info)
    ) do
      {:ok, new_src_ib_gib}
    else
      {:error, reason} when is_bitstring(reason) -> {:error, reason}
      {:error, reason} -> {:error, inspect reason}
      error -> {:error, inspect error}
    end
  end

  # ----------------------------------------------------------------------------
  # Identity
  # ----------------------------------------------------------------------------
  # The user can add multiple layers of identity. The user starts off with an
  # identity from the session. This is the analog to an "anonymous" identity.
  # The user can also add identity by logging in with a valid email. We will
  # allow for an optional small challenge, kind of like a one-time pin. We will
  # send a link to the email address which contains a random token (not the pin)
  # and store this token in session. When the user clicks on the email link,
  # We will see the token in session and match it against the link. If the
  # one-time pin was provided, we will challenge for that as well. If this
  # succeeds, we will create the email identity if needed, spin off a mut8
  # identity to "log" the successful login and return the original email
  # identity. This way, the user is always "signing" with the same identity
  # ibGib, but we still keep a record of successful logins. I think we'll also
  # "log" invalid login attempts as well.
  # ----------------------------------------------------------------------------

  defpat unidentemail_form_data_(
    src_ib_gib_()
  )

  def unident(conn, %{"unidentemail_form_data" => unidentemail_form_data_(...) = form_data} = params) do
    with(
      {:ok, {conn, new_identity_ib_gibs}} <- 
        remove_identity_from_session(conn, src_ib_gib),

      session_identity_ib_gib <-
        conn |> get_session(@ib_session_ib_gib_key),
        # publish
      _ <- EventChannel.broadcast_ib_gib_event(:unident_email,
                                              {session_identity_ib_gib,
                                               src_ib_gib})
      # # publish
      # _ <- EventChannel.broadcast_ib_gib_event(:unident_email,
      #                                          {session_identity_ib_gib,
      #                                           src_ib_gib})
    ) do
      conn
      |> send_resp(200, "ok")
    else
      {:error, reason} ->
        _ = Logger.error reason
        # This still sends the status 
        conn
        |> send_resp(500, reason)
        |> halt()
        
      error -> 
        _ = Logger.error(inspect error)
        conn
        |> send_resp(500, inspect error)
        |> halt()
    end
  end

  # idempotent removal of identity_ib_gib from connection session.
  defp remove_identity_from_session(conn, identity_ib_gib)
    when identity_ib_gib !== @root_ib_gib do
    with(
      _ <- Logger.debug("BEFORE conn: #{inspect conn}\nidentity_ib_gib: #{identity_ib_gib}" |> ExChalk.bg_blue |> ExChalk.yellow),
      
      identity_ib_gibs <- conn |> get_session(@ib_identity_ib_gibs_key),
      new_identity_ib_gibs <- 
        identity_ib_gibs 
        |> Enum.filter(&(&1 !== identity_ib_gib)),
      
      conn <-
        conn
        |> put_session(@ib_identity_ib_gibs_key, new_identity_ib_gibs),

      _ <- Logger.debug("AFTER conn: #{inspect conn}\nidentity_ib_gib: #{identity_ib_gib}" |> ExChalk.bg_blue |> ExChalk.yellow)
    ) do
      {:ok, {conn, new_identity_ib_gibs}}
    else
      {:error, reason} when is_bitstring(reason) -> {:error, reason}
      {:error, reason} -> {:error, inspect reason}
      error -> {:error, inspect error}
    end
  end

  # Email identity clause
  def ident(conn,
            %{"identemail_form_data" =>
              %{"ident_type" => "email",
                "ident_text" => email_addr,
                "ident_pin" => ident_pin,
                "src_ib_gib" => src_ib_gib}} = _params) do
    Logger.metadata(x: :ident_1)
    _ = Logger.debug "conn: #{inspect conn}"

    ident(conn,
          %{"ident_type" => "email",
            "ident_text" => email_addr,
            "ident_pin" => ident_pin,
            "src_ib_gib" => src_ib_gib})
  end
  def ident(conn,
            %{"ident_type" => "email",
              "ident_text" => email_addr,
              "ident_pin" => ident_pin,
              "src_ib_gib" => src_ib_gib} = _params) do
    Logger.metadata(x: :ident_2)
    _ = Logger.debug "conn: #{inspect conn}"

    if validate(:email_addr, email_addr) and validate(:ib_gib, src_ib_gib) do
      _ = Logger.debug "ident is valid. email_addr: #{email_addr}"

      case start_email_impl(conn, src_ib_gib, email_addr, ident_pin) do
        {:ok, conn} ->
          redirect_ib_gib =
            if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
          conn
          |> put_flash(:info, gettext "Email sent. Open the link provided in this browser.")
          |> redirect(to: "/ibgib/#{redirect_ib_gib}")

        {:error, reason} ->
          redirect_ib_gib =
            if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
          _ = Logger.error reason
          friendly_emsg = dgettext "error", @emsg_email_send_failed
          conn
          |> put_flash(:error, friendly_emsg)
          |> redirect(to: "/ibgib/#{redirect_ib_gib}")
      end
    else
      redirect_ib_gib =
        if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
      _ = Logger.debug "ident is INVALID. email_addr: #{email_addr}"
      friendly_emsg = dgettext "error", @emsg_invalid_email
      conn
      |> put_flash(:error, friendly_emsg)
      |> redirect(to: "/ibgib/#{redirect_ib_gib}")
    end
  end
  # Last step: At this point, the user has clicked on the link and entered the
  # pin. We will check the token again, the pin, and log in the user if valid,
  # i.e. add email identity ib^gib to identity_ib_gibs in session.
  def ident(conn,
            %{"enterpin_form_data" =>
              %{"token" => token,
                "ident_pin" => ident_pin}} = _params)
    when is_bitstring(token) and is_bitstring(ident_pin) do
    Logger.metadata(x: :ident_email_login_token)
    # _ = Logger.warn "Hey, we have a token and an ident_pin.\ntoken: #{token}\nident_pin: #{ident_pin}"
    _ = Logger.debug "conn: #{inspect conn}"

    case complete_email_impl(conn, token, ident_pin) do
      {:ok, {conn, email_addr, src_ib_gib}} ->
        redirect_ib_gib =
          if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
        conn
        |> put_flash(:info, gettext("Success! You have now added the email address to your current identity. Delete the login email we sent you, close this window, and return to your previous ibGib window. See https://github.com/ibgib/ibgib/wiki/identity for more info. (Note: We're working on streamlining this so you don't have to do this close window rigamarole...)") <> "\nEmail Address: #{email_addr}")
        |> redirect(to: "/")

      {:error, reason} ->
        _ = Logger.error reason
        friendly_emsg = dgettext "error", @emsg_ident_email_failed
        conn
        |> put_flash(:error, friendly_emsg)
        |> redirect(to: "/ibgib/#{@root_ib_gib}")
    end
  end
  # Login ident step 2 (ugh, this is an ugly controller.)
  # At this point, the user has clicked on the link but not yet entered the pin.
  def ident(conn, %{"token" => token} = _params) do
    Logger.metadata(x: :ident_email_login_token)
    _ = Logger.debug "conn: #{inspect conn}"

    case continue_email_impl(conn, token) do
      # A pin was provided, so we must first confirm the pin before logging in.
      {:ok, {conn, :enter_pin}} ->
        _ = Logger.debug "enter_pin"
        conn
        |> put_flash(:info, gettext("Excellent! You're almost there. Now just enter the same pin you entered when first logging in. See https://github.com/ibgib/ibgib/wiki/identity for more info."))
        |> assign(:ident_email_token_key, token)
        |> render("enterpin.html")

      # No pin is used so skip it and go directly to logging in.
      {:ok, {conn, :skip_pin}} ->
        _ = Logger.debug "skip_pin"
        ident(conn, %{"enterpin_form_data" =>
                      %{"token" => token,
                        "ident_pin" => ""}})

      # Oops
      {:error, reason} ->
        _ = Logger.error reason
        friendly_emsg = dgettext("error", @emsg_ident_email_failed)
        conn
        |> put_flash(:error, friendly_emsg)
        |> redirect(to: "/ibgib/#{@root_ib_gib}")
    end
  end
  def ident(conn, _params) do
    Logger.error "Unknown ident params.\nconn:\n#{inspect conn}"
    friendly_emsg = dgettext("error", @emsg_ident_email_failed)
    conn
    |> put_flash(:error, friendly_emsg)
    |> redirect(to: "/ibgib/#{@root_ib_gib}")
  end

  # This is the first step in the workflow of logging in with email. This
  # will generate a new token, store the token and timestamp in session,
  # and fire off the email.
  defp start_email_impl(conn, src_ib_gib, email_addr, ident_pin) do
    _ = Logger.debug "src_ib_gib: #{src_ib_gib}\nemail_addr: #{email_addr}"
    with(
      # Collect our data
      token <- hash(new_id()),
      pin_provided <- (String.length(ident_pin) > 0) |> to_string,
      ident_pin_hash <- hash(ident_pin),

      # Save data in appropriate places
      {:ok, :ok} <-
        WebGib.Data.save_ident_email_info(email_addr, token, ident_pin_hash),
      conn <- put_session(conn, @ident_email_email_addr_key, email_addr),
      conn <- put_session(conn, @ident_email_pin_provided_key, pin_provided),
      conn <- put_session(conn,
                          @ident_email_timestamp_key,
                          :erlang.system_time(:milli_seconds)),
      conn <- put_session(conn,
                          @ident_email_src_ib_gib_key,
                          src_ib_gib),

      # Send email
      {:ok, :ok} <- send_email_login(email_addr, token)
    ) do
      {:ok, conn}
    else
      {:error, reason} when is_bitstring(reason) -> {:error, reason}
      {:error, reason} -> {:error, inspect reason}
      error -> {:error, inspect error}
    end
  end

  defp send_email_login(email_addr, token) do
    try do
      WebGib.Mailer.send_login_token(email_addr, token)
      {:ok, :ok}
    rescue
      e in RuntimeError ->
        Logger.error "WebGib.Mailer failed to send email. e:\n#{inspect e}"
        {:error, inspect e}
    end
  end

  # Login ident step 2 (ugh, this is an ugly controller.)
  # At this point, the user has clicked on the link but not yet entered the pin.
  defp continue_email_impl(conn, _token) do
    with(
      {:ok, :ok} <- check_timestamp_expiration(conn),
      # At this point, the token is in the URL, so no biggie putting in session.
      pin_provided <- get_session(conn, @ident_email_pin_provided_key),
      pin_action <- (if pin_provided == "true", do: :enter_pin, else: :skip_pin)
    ) do
      _ = Logger.debug("pin_action: #{pin_action}" |> ExChalk.bg_yellow)
      {:ok, {conn, pin_action}}
    else
      {:error, reason} when is_bitstring(reason) -> {:error, reason}
      {:error, reason} -> {:error, inspect reason}
      error -> {:error, inspect error}
    end
  end

  defp check_timestamp_expiration(conn) do
    timestamp = get_session(conn, @ident_email_timestamp_key) || 0
    elapsed_ms =
      :erlang.system_time(:milli_seconds) - timestamp
    # Logger.debug("timestamp: #{timestamp}.\nelapsed_ms: #{elapsed_ms}" |> ExChalk.bg_blue |> ExChalk.magenta)
    if elapsed_ms <= @max_ident_elapsed_ms do
      {:ok, :ok}
    else
      {:error, @emsg_ident_email_token_expired}
    end
  end

  # If this fails at any point, the whole process must be restarted.
  # This is acceptable, since it's a (relatively) fast workflow and the
  # pin is optional. The pin is not supposed to be complicated, since it is a
  # one-time pin and is only adding a secondary layer of defense, so pin typos
  # should be rare.
  defp complete_email_impl(conn, token, ident_pin) do
    _ = Logger.debug "token: #{token}\nident_pin: #{ident_pin}"
    with(
      # Double-check our timestamp expiration, clean up if passes.
      {:ok, :ok} <- check_timestamp_expiration(conn),

      # Gather our previous info
      email_addr <- get_session(conn, @ident_email_email_addr_key),
      src_ib_gib <- get_session(conn, @ident_email_src_ib_gib_key),
      ident_pin_hash <- hash(ident_pin),

      # Cleanup
      conn <- put_session(conn, @ident_email_timestamp_key, nil),
      conn <- put_session(conn, @ident_email_email_addr_key, nil),
      conn <- put_session(conn, @ident_email_src_ib_gib_key, nil),
      conn <- put_session(conn, @ident_email_pin_provided_key, nil),

      # Get token for email_addr and ident_pin_hash and compare.
      {:ok, got_token} <-
        WebGib.Data.get_ident_email_token(email_addr, ident_pin_hash),
      {:ok, :ok} <- check_token_match(token, got_token),

      # Token is valid, pin is valid, so add the identity if not already added.
      # If the `email_addr` is new to ibgib, this will **create** the identity
      # ib_gib first and then add the ib^gib to the session identity_ib_gibs.
      {:ok, {conn, identity_ib_gib}} <-
        add_identity_to_session(conn, email_addr),
      session_identity_ib_gib <-
        conn |> get_session(@ib_session_ib_gib_key),

        # publish
      _ <- EventChannel.broadcast_ib_gib_event(:ident_email,
                                              {session_identity_ib_gib,
                                               identity_ib_gib})
    ) do
      {:ok, {conn, email_addr, src_ib_gib}}
    else
      {:error, reason} when is_bitstring(reason) -> {:error, reason}
      {:error, reason} -> {:error, inspect reason}
      error -> {:error, inspect error}
    end
  end

  defp check_token_match(token, got_token) do
    if token == got_token do
      {:ok, :ok}
    else
      {:error, @emsg_ident_email_token_mismatch}
    end
  end

  defp add_identity_to_session(conn, email_addr) do
    with(
      # Thanks http://blog.danielberkompas.com/elixir/2015/06/16/rate-limiting-a-phoenix-api.html
      # ip <- conn.remote_ip |> Tuple.to_list |> Enum.join("."),
      priv_data <- %{"email_addr" => email_addr},
      pub_data <- %{
                    "type" => "email",
                    "email_addr" => email_addr,
                    # "ip" => ip # causes problems with mut8 identity
                  },
      {:ok, identity_ib_gib} <- Identity.get_identity(priv_data, pub_data),
      identity_ib_gibs <- conn |> get_session(@ib_identity_ib_gibs_key),
      conn <-
        (if Enum.member?(identity_ib_gibs, identity_ib_gib) do
           conn
         else
           conn
           |> put_session(@ib_identity_ib_gibs_key,
                          identity_ib_gibs ++ [identity_ib_gib])
         end)
    ) do
      {:ok, {conn, identity_ib_gib}}
    else
      {:error, reason} when is_bitstring(reason) -> {:error, reason}
      {:error, reason} -> {:error, inspect reason}
      error -> {:error, inspect error}
    end
  end

  # ----------------------------------------------------------------------------
  # Query
  # ----------------------------------------------------------------------------


  def query(conn, %{
                     "query_form_data" => %{
                      "src_ib_gib" => src_ib_gib} = query_params
                    } = _params) do
    Logger.metadata(x: :query)
    _ = Logger.debug "conn: #{inspect conn}"

    if validate(:query_params, query_params) and
       validate(:ib_gib, src_ib_gib) do
      _ = Logger.debug "query is valid. query_params: #{inspect query_params}"

      case query_impl(conn, src_ib_gib, query_params) do
        {:ok, query_result_ib_gib} ->
          conn
          |> redirect(to: "/ibgib/#{query_result_ib_gib}")

        {:error, reason} ->
          redirect_ib_gib =
            if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
          _ = Logger.error reason
          friendly_emsg = dgettext "error", @emsg_invalid_query
          conn
          |> put_flash(:error, friendly_emsg)
          |> redirect(to: "/ibgib/#{redirect_ib_gib}")
      end
    else
      redirect_ib_gib =
        if valid_ib_gib?(src_ib_gib), do: src_ib_gib, else: @root_ib_gib
      _ = Logger.warn "query is INVALID.\nquery_params: #{inspect query_params}"
      friendly_emsg = dgettext "error", @emsg_invalid_query
      conn
      |> put_flash(:error, friendly_emsg)
      |> redirect(to: "/ibgib/#{redirect_ib_gib}")
    end
  end

  # I don't want to see the lint message for this right now. I'm aware that
  # the signature is just growing. But it's more concise than destructuring
  # the incoming params map.
  # @lint false
  # defp query_impl(conn, src_ib_gib, search_ib, ib_query_type, latest, search_data) do
  defp query_impl(conn, src_ib_gib, query_params) do

    _ = Logger.debug "src_ib_gib: #{src_ib_gib}\nquery_params: #{inspect query_params}"

    with(
      # Identities (need plug)
      identity_ib_gibs <- conn |> get_session(@ib_identity_ib_gibs_key),

      # We will query off of the given src
      {:ok, src} <- IbGib.Expression.Supervisor.start_expression(src_ib_gib),

      # Build the query options
      {:ok, query_opts} <-
        build_query_opts(identity_ib_gibs, query_params),

      # Execute the query itself, which creates the query_result ib_gib
      {:ok, query_result} <-
        src |> Expression.query(identity_ib_gibs, query_opts),

      # Return the query's ib^gib
      {:ok, query_result_info} <- query_result |> Expression.get_info,
      {:ok, query_result_ib_gib} <- get_ib_gib(query_result_info)
    ) do
      {:ok, query_result_ib_gib}
    else
      error -> default_handle_error(error)
    end
  end

  defp build_query_opts(identity_ib_gibs, query_params)
    when is_list(identity_ib_gibs) and
         length(identity_ib_gibs) > 1 do

    # We're searching only for the user's ibgib, and we're going to do a
    # "withany" query. If we kept in the root, then it would return everything
    # since everybody has the root in its identity_ib_gibs. 
    # We also don't want any node identities in the query. We're looking only
    # for session and email identities.
    query_identities = 
      identity_ib_gibs
      |> Enum.filter(&(&1 != @root_ib_gib))
      |> Enum.filter(fn(identity_ib_gib) -> 
           {ib, _gib} = separate_ib_gib!(identity_ib_gib)
           [type, _hash] = String.split(ib, "_")
           type !== "node" 
         end)

    _ = Logger.debug("query_identities: #{inspect query_identities}" |> ExChalk.bg_green |> ExChalk.black)

    # All queries (currently) look only within the current user's identities.
    query_opts =
      do_query()
      |> where_rel8ns("identity", "withany", "ibgib", query_identities)

    _ = Logger.debug("query_opts: #{inspect query_opts}" |> ExChalk.bg_green |> ExChalk.black)

    # Add ib_search if given
    search_ib = query_params["search_ib"]
    query_opts =
      if search_ib != nil and String.length(search_ib) > 0 do
        ib_search_method =
          case query_params["ib_query_type"] do
            "is" -> "is"
            "has" -> "like"
          end

        query_opts |> where_ib(ib_search_method, search_ib)
      else
        query_opts
      end

    # Add search_data if given
    search_data = query_params["search_data"]
    query_opts =
      if search_data != nil and String.length(search_data) > 0 do
        query_opts |> where_data("value", "like", search_data)
      else
        query_opts
      end

    # Add latest if given
    latest = query_params["latest"] != nil
    query_opts =
      if latest do
        query_opts |> most_recent_only()
      else
        query_opts
      end

    # include rel8ns
    # We're going to check if the types are any of these by checking for the
    # relevant ancestors.
    include_pic = query_params["include_pic"] != nil
    include_comment = query_params["include_comment"] != nil
    include_query = query_params["include_query"] != nil
    include_dna = query_params["include_dna"] != nil

    # Build up list of what we're including
    include_rel8n_ibgibs =
      []
      |> add_rel8n_ibgibs(include_pic, ["pic#{@delim}gib"])
      |> add_rel8n_ibgibs(include_comment, ["comment#{@delim}gib"])
      |> add_rel8n_ibgibs(include_query, ["query#{@delim}gib"])
      |> add_rel8n_ibgibs(include_dna,
                          ["plan#{@delim}gib",
                           "fork#{@delim}gib",
                           "mut8#{@delim}gib",
                           "rel8#{@delim}gib"])

    _ = Logger.debug("include_rel8n_ibgibs: #{inspect include_rel8n_ibgibs}" |> ExChalk.bg_green |> ExChalk.black)
    query_opts =
      if length(include_rel8n_ibgibs) > 0 do
        query_opts
        |> where_rel8ns("ancestor", "withany", "ibgib", include_rel8n_ibgibs)
      else
        query_opts
      end

    _ = Logger.debug("query_opts: #{inspect query_opts}" |> ExChalk.bg_green |> ExChalk.black)

    {:ok, query_opts}
  end
  defp build_query_opts(identity_ib_gibs, query_params) do
    invalid_args([identity_ib_gibs, query_params])
  end

  defp add_rel8n_ibgibs(agg_list, true, ibgibs) do
    agg_list ++ ibgibs
  end
  defp add_rel8n_ibgibs(agg_list, false, _ibgibs) do
    agg_list
  end


  # User must be signed in with an email identity to upload pics.
  defp authorize_upload(conn, _params) do
    identity_ib_gibs = get_session(conn, @ib_identity_ib_gibs_key)
    if has_email_identity?(identity_ib_gibs) do
      conn
    else
      _ = Logger.info("User not authorized to upload pic.")
      emsg = "You must be identified by at least one email account to upload. To identify yourself with an email address, click on the root ibGib (the green one that pops up when you click the background) and click the white \"Login\" button.\n\nFor a slightly outdated walkthru of this, see https://github.com/ibgib/ibgib/wiki/Identify-with-Email---Step-By-Step-Walkthru.\n\nAnd for more information on ibGib Identity, see https://github.com/ibgib/ibgib/wiki/Identity for more info."
      conn
      |> send_resp(403, emsg)
      |> halt
    end
  end

  defp has_email_identity?(identity_ib_gibs) when is_list(identity_ib_gibs) do
    identity_ib_gibs
    |> Enum.any?(&(String.starts_with?(&1, "email_")))
  end
  defp has_email_identity?(_identity_ib_gibs) do
    false
  end


end
