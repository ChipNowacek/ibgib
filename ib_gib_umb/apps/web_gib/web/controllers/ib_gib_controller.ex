defmodule WebGib.IbGibController do
  @moduledoc """
  Controller related to ib_gib code.
  """

  # ----------------------------------------------------------------------------
  # Usings, imports, etc.
  # ----------------------------------------------------------------------------

  use WebGib.Web, :controller

  use IbGib.Constants, :validation
  use WebGib.Constants, :config



  alias IbGib.TransformFactory.Mut8Factory
  alias IbGib.Expression

  # ----------------------------------------------------------------------------
  # Controller Commands
  # ----------------------------------------------------------------------------

  @doc """
  This should show the "Home" ib^gib.
  """
  def index(conn, params) do
    _ = Logger.warn "conn: #{inspect conn}"
    _ = Logger.debug "index. params: #{inspect params}"

    conn
    |> assign(:ib, "ib")
    |> assign(:gib, "gib")
    |> assign(:ib_gib, @root_ib_gib)
    |> add_meta_query
    |> redirect(to: ib_gib_path(WebGib.Endpoint, :show, get_session(conn, @meta_query_result_ib_gib_key)))
  end

  defp add_meta_query(conn) do
    _ = Logger.debug "meta_query_ib_gib: #{@meta_query_ib_gib_key}"
    _ = Logger.debug "meta_query_result_ib_gib: #{@meta_query_result_ib_gib_key}"

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
         {:ok, thing_info} <- thing |> Expression.get_info do
        thing_data = thing_info[:data]
        thing_relations = thing_info[:rel8ns]
        _ = Logger.warn "thing_relations: #{inspect thing_relations}"
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
      _ = Logger.error "#{error_msg}. (#{inspect result_term})"
      conn
      |> put_flash(:error, error_msg)
      |> redirect(to: "/ibgib")
    end
  end

  # ----------------------------------------------------------------------------
  # JSON Api
  # ----------------------------------------------------------------------------

  def get(conn, %{"ib_gib" => ib_gib} = params) do
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
    ib_gib_node = %{"id" => "ib#{@delim}gib", "name" => "ib", "cat" => "ibGib", "ibgib" => "ib#{@delim}gib", "js_id" => get_js_id}
    ib_node = %{"id" => ib_node_ibgib, "name" => ib_node_ib, "cat" => "ib", "ibgib" => ib_node_ibgib, "js_id" => get_js_id, "ib" => ib_node_ib, "gib" => ib_node_gib, "render" => get_render(ib_node_ibgib, ib_node_ib, ib_node_gib)}

    nodes = [ib_gib_node, ib_node]

    links = []

    _ = Logger.warn "info[:rel8ns]: #{inspect info[:rel8ns]}"
    {nodes, links} =
      Enum.reduce(info[:rel8ns],
                  {nodes, links},
                  fn({rel8n, rel8n_ibgibs}, {acc_nodes, acc_links}) ->

        # First get the node representing the rel8n itself.
        {group_node, group_link} = create_rel8n_group_node_and_link(rel8n, ib_node)

        # Now get the node and links for each ib^gib that belongs to that
        # rel8n.
        {item_nodes, item_links, prev_ib_gib} =
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
    rel8n_node = %{"id" => rel8n, "name" => rel8n, "cat" => "rel8n", "js_id" => get_js_id}
    # {"source": "Champtercier", "target": "Myriel", "value": 1},
    rel8n_link = %{"source" => ib_node["id"], "target" => rel8n, "value" => 1}
    result = {rel8n_node, rel8n_link}
    _ = Logger.debug "group node: #{inspect result}"
    result
  end

  @doc """
  These will relate to each other, not all to the group
  """
  @linear_rel8ns ["past", "ancestor", "dna"]

  defp create_rel8n_item_node_and_link(ibgib, rel8n, prev_ibgib) do
    {ib, gib} = separate_ib_gib!(ibgib)
    item_node = %{
      "id" => "#{rel8n}: #{ibgib}",
      "name" => ib,
      "cat" => rel8n,
      "ibgib" => "#{ibgib}",
      "js_id" => get_js_id,
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

  def mut8(conn, %{"mut8n" => %{"key" => key, "value" => value, "src_ib_gib" => src_ib_gib} = mut8n} = params) do
    _ = Logger.debug "conn: #{inspect conn}"
    _ = Logger.debug "conn.params: #{inspect conn.params}"
    _ = Logger.debug "params: #{inspect params}"
    # data_key = conn.params["mut8n"]["key"]
    # data_value = conn.params["mut8n"]["value"]
    # data_key = params["mut8n"]["key"]
    # data_value = params["mut8n"]["value"]
    # msg = "key: #{data_key}.\nvalue: #{data_value}"
    msg = "key: #{key}\nvalue: #{value}"

    _ = Logger.debug msg

    do_mut8(conn, src_ib_gib, {:add_update_key, key, value})
  end
  def mut8(conn, %{"mut8n" => %{"key" => key, "action" => action, "src_ib_gib" => src_ib_gib} = mut8n} = params) do
    _ = Logger.debug "conn: #{inspect conn}"
    _ = Logger.debug "conn.params: #{inspect conn.params}"
    _ = Logger.debug "params: #{inspect params}"
    # data_key = conn.params["mut8n"]["key"]
    # data_value = conn.params["mut8n"]["value"]
    # data_key = params["mut8n"]["key"]
    # data_value = params["mut8n"]["value"]
    # msg = "key: #{data_key}.\nvalue: #{data_value}"
    msg = "key: #{key}\naction: #{action}"

    _ = Logger.debug msg

    do_mut8(conn, src_ib_gib, {:remove_key, key})
  end

  defp do_mut8(conn, src_ib_gib, {:add_update_key, key, value}) do
    _ = Logger.debug "."
    case mut8_impl(src_ib_gib, {:add_update_key, key, value}) do
      {:ok, mut8d_thing} ->
        Logger.info "mut8d_thing: #{inspect mut8d_thing}"

        mut8d_thing_info = mut8d_thing |> Expression.get_info!
        ib = mut8d_thing_info[:ib]
        gib = mut8d_thing_info[:gib]
        ib_gib = get_ib_gib!(ib, gib)

        conn
        |> redirect(to: "/ibgib/#{ib_gib}")
      other ->
        # put flash error
        error_msg = dgettext "error", "Mut8 failed."
        _ = Logger.error "#{error_msg}. (#{inspect other})"
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: "/ibgib/#{src_ib_gib}")
    end
  end
  defp do_mut8(conn, src_ib_gib, {:remove_key, key}) do
    _ = Logger.debug "."
    case mut8_impl(src_ib_gib, {:remove_key, key}) do
      {:ok, mut8d_thing} ->
        Logger.info "mut8d_thing: #{inspect mut8d_thing}"

        mut8d_thing_info = mut8d_thing |> Expression.get_info!
        ib = mut8d_thing_info[:ib]
        gib = mut8d_thing_info[:gib]
        ib_gib = get_ib_gib!(ib, gib)

        conn
        |> redirect(to: "/ibgib/#{ib_gib}")
      other ->
        # put flash error
        error_msg = dgettext "error", "Mut8 failed."
        _ = Logger.error "#{error_msg}. (#{inspect other})"
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: "/ibgib/#{src_ib_gib}")
    end
  end

  defp mut8_impl(src_ib_gib, {:add_update_key, key, value})
      when is_bitstring(src_ib_gib) and
           is_bitstring(key) and is_bitstring(value) and
           src_ib_gib !== "" and key !== "" do
      _ = Logger.debug "src_ib_gib: #{src_ib_gib}, key: #{key}, value: #{value}"

      {:ok, src} = IbGib.Expression.Supervisor.start_expression(src_ib_gib)
      src |> Expression.mut8(Mut8Factory.add_or_update_key(key, value))
  end
  defp mut8_impl(src_ib_gib, {:remove_key, key})
      when is_bitstring(src_ib_gib) and
           is_bitstring(key) and
           src_ib_gib !== "" and key !== "" do
      _ = Logger.debug "src_ib_gib: #{src_ib_gib}, key: #{key}"

      {:ok, src} = IbGib.Expression.Supervisor.start_expression(src_ib_gib)
      src |> Expression.mut8(Mut8Factory.remove_key(key))
  end

  # ----------------------------------------------------------------------------
  # Fork
  # ----------------------------------------------------------------------------

  def fork(conn, %{"fork_form_data" => %{"dest_ib" => dest_ib, "src_ib_gib" => src_ib_gib}} = params) do
    _ = Logger.debug "conn: #{inspect conn}"
    _ = Logger.debug "conn.params: #{inspect conn.params}"
    _ = Logger.debug "params: #{inspect params}"
    msg = "dest_ib: #{dest_ib}"

    if validate(:dest_ib, dest_ib) and validate(:ib_gib, src_ib_gib) do
      do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib})
    else
      conn
      |> put_flash(:error, @emsg_invalid_dest_ib)
      |> redirect(to: "/ibgib/#{src_ib_gib}")
    end
  end
  def fork(conn, %{"dest_ib" => dest_ib, "src_ib_gib" => src_ib_gib} = params) do
    _ = Logger.debug "conn: #{inspect conn}"
    _ = Logger.debug "conn.params: #{inspect conn.params}"
    _ = Logger.debug "params: #{inspect params}"
    msg = "dest_ib: #{dest_ib}"

    if validate(:dest_ib, dest_ib) and validate(:ib_gib, src_ib_gib) do
      do_fork(conn, %{"src_ib_gib" => src_ib_gib, "dest_ib" => dest_ib})
    else
      conn
      |> put_flash(:error, @emsg_invalid_dest_ib)
      |> redirect(to: "/ibgib/#{src_ib_gib}")
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
        # put flash error
        error_msg = dgettext "error", "Fork failed."
        _ = Logger.error "#{error_msg}. (#{inspect other})"
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: "/ibgib")
    end
  end

  defp fork_impl(conn, root, src_ib_gib \\ @root_ib_gib, dest_ib \\ new_id)
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
      fork_impl(root, src_ib_gib, new_id)
  end

  # ----------------------------------------------------------------------------
  # Comment
  # ----------------------------------------------------------------------------

  def comment(conn, %{"comment_form_data" => %{"comment_text" => comment_text, "src_ib_gib" => src_ib_gib}} = params) do
    Logger.metadata(x: :comment_1)
    _ = Logger.debug "conn: #{inspect conn}"

    comment(conn, %{"comment_text" => comment_text, "src_ib_gib" => src_ib_gib})
  end
  def comment(conn, %{"comment_text" => comment_text, "src_ib_gib" => src_ib_gib} = params) do
    Logger.metadata(x: :comment_2)
    _ = Logger.debug "conn: #{inspect conn}"
    msg = "comment_text: #{comment_text}"

    _ = Logger.warn "@root_ib_gib: #{@root_ib_gib}"

    if validate(:comment_text, comment_text) and
                validate(:ib_gib, src_ib_gib) and
                src_ib_gib != @root_ib_gib do
      _ = Logger.debug "comment is valid. comment_text: #{comment_text}"

      case comment_impl(conn, src_ib_gib, comment_text) do
        {:ok, new_src_ib_gib} ->
          conn
          |> redirect(to: "/ibgib/#{new_src_ib_gib}")

        {:error, reason} ->
          _ = Logger.error reason
          friendly_emsg = dgettext "error", @emsg_invalid_comment
          conn
          |> put_flash(:error, friendly_emsg)
          |> redirect(to: "/ibgib")
      end
    else
      _ = Logger.debug "comment is INVALID. comment_text: #{comment_text}"
      friendly_emsg = dgettext "error", @emsg_invalid_comment
      conn
      |> put_flash(:error, friendly_emsg)
      |> redirect(to: "/ibgib/#{src_ib_gib}")
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

  def pic(conn, %{"pic_form_data" => %{"pic_data" => pic_data, "src_ib_gib" => src_ib_gib}} = params) do
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
            "src_ib_gib" => src_ib_gib} = params) do
    Logger.metadata(x: :pic_2)
    _ = Logger.debug "conn: #{inspect conn}"
    _ = Logger.warn "pic_data: #{inspect pic_data}"

    if validate(:pic_data, {content_type, filename, path}) and
                validate(:ib_gib, src_ib_gib) and
                src_ib_gib != @root_ib_gib do
      _ = Logger.debug "pic is valid. content_type, filename, path: #{content_type}, #{filename}, #{path}"

      case pic_impl(conn, src_ib_gib, content_type, filename, path) do
        {:ok, new_src_ib_gib} ->
          conn
          |> redirect(to: "/ibgib/#{new_src_ib_gib}")

        {:error, reason} ->
          _ = Logger.error reason
          # friendly_emsg = dgettext "error", @emsg_invalid_pic
          friendly_emsg = gettext "The pic is Invalid. :-/"
          conn
          |> put_flash(:error, friendly_emsg)
          |> redirect(to: "/ibgib")
      end
    else

      _ = Logger.debug "pic is INVALID. pic_data: #{pic_data}"
      # friendly_emsg = dgettext("error", @emsg_invalid_pic)
      friendly_emsg = gettext "The pic is Invalid. :-/"
      conn
      |> put_flash(:error, friendly_emsg)
      |> redirect(to: "/ibgib/#{src_ib_gib}")
    end
  end

  defp pic_impl(conn, src_ib_gib, content_type, filename, path) do
    _ = Logger.debug "src_ib_gib: #{src_ib_gib}\ncontent_type, filename, path: #{content_type}, #{filename}, #{path}"

    with(
      identity_ib_gibs <- conn |> get_session(@ib_identity_ib_gibs_key),
      {:ok, src} <- IbGib.Expression.Supervisor.start_expression(src_ib_gib),
      {:ok, pic_gib} <-
        IbGib.Expression.Supervisor.start_expression("pic#{@delim}gib"),
      {:ok, pic} <-
        pic_gib
        |> Expression.fork(identity_ib_gibs,
                           "pic"),
      # Generates a bin_id to use in image data.
      {:ok, {bin_id, ext}} <- save_to_bin_store(conn, content_type, path, filename),
      {:ok, pic} <-
        pic
        |> Expression.mut8(identity_ib_gibs,
                           %{
                             "content_type" => content_type,
                             "filename" => filename,
                             "bin_id" => bin_id,
                             "ext" => ext
                            }),
      {:ok, new_src} <-
        src
        |> Expression.rel8(pic, identity_ib_gibs, ["pic"]),
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

  defp save_to_bin_store(conn, content_type, path, filename) do
    _ = Logger.debug "yo"
    with(
      {:ok, body} <- File.read(path),
      :ok <- Logger.debug("1"),
      binary_data <- IO.iodata_to_binary(body),
      :ok <- Logger.debug("2"),
      binary_id <- hash(binary_data),
      # stp <- static_path(conn, "/files/yo.png"),
      # :ok <- Logger.debug("3. path: #{path}\nstatic_path: #{stp}"),
      :ok <- Logger.debug("3. path: #{path}"),
      {:ok, :ok} <- ensure_path_exists(@upload_files_path),
      ext <- Path.extname(filename),
      target_full_path <-
        Path.join(@upload_files_path, binary_id <> ext),
      :ok <- Logger.debug("4. target_full_path: #{target_full_path}"),
      # {:ok, _bytes_copied} <- File.copy(path, target_full_path)
      :ok <- File.cp(path, target_full_path)
      # the binary_id is a hash of the binary data.
      # {:ok, binary_id} <- IbGib.Data.save_binary(binary_data)
    ) do
      {:ok, {binary_id, ext}}
    else
      {:error, reason} when is_bitstring(reason) -> {:error, reason}
      {:error, reason} -> {:error, inspect reason}
      error -> {:error, inspect error}
    end
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

  def link(conn, %{"link_form_data" => %{"link_text" => link_text, "src_ib_gib" => src_ib_gib}} = params) do
    Logger.metadata(x: :link_1)
    _ = Logger.debug "conn: #{inspect conn}"

    link(conn, %{"link_text" => link_text, "src_ib_gib" => src_ib_gib})
  end
  def link(conn, %{"link_text" => link_text, "src_ib_gib" => src_ib_gib} = params) do
    Logger.metadata(x: :link_2)
    _ = Logger.debug "conn: #{inspect conn}"
    msg = "link_text: #{link_text}"

    _ = Logger.warn "@root_ib_gib: #{@root_ib_gib}"
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
          _ = Logger.error reason
          friendly_emsg = dgettext "error", @emsg_invalid_link
          conn
          |> put_flash(:error, friendly_emsg)
          |> redirect(to: "/ibgib")
      end
    else
      _ = Logger.debug "link is INVALID. link_text: #{link_text}"
      friendly_emsg = dgettext "error", @emsg_invalid_link
      conn
      |> put_flash(:error, friendly_emsg)
      |> redirect(to: "/ibgib/#{src_ib_gib}")
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
  # The user can add multiple levels of identity. The user starts off with an
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


  # Email identity clause
  def ident(conn,
            %{"ident_form_data" =>
              %{"ident_type" => "email",
                "ident_text" => email_addr,
                "ident_pin" => ident_pin,
                "src_ib_gib" => src_ib_gib}} = params) do
    Logger.metadata(x: :ident_1)
    _ = Logger.debug "conn: #{inspect conn}"

    ident(conn,
          %{"ident_type" => "email",
            "ident_text" => email_addr,
            "ident_pin" => ident_pin,
            "src_ib_gib" => src_ib_gib})
  end
  # Email identity clause
  def ident(conn,
            %{"ident_type" => "email",
              "ident_text" => email_addr,
              "ident_pin" => ident_pin,
              "src_ib_gib" => src_ib_gib} = params) do
    Logger.metadata(x: :ident_2)
    _ = Logger.debug "conn: #{inspect conn}"
    msg = "email_addr: #{email_addr}"

    if validate(:email_addr, email_addr) and validate(:ib_gib, src_ib_gib) do
      _ = Logger.debug "ident is valid. email_addr: #{email_addr}"

      case start_email_impl(conn, src_ib_gib, email_addr, ident_pin) do
        {:ok, conn} ->
          conn
          |> put_flash(:info, gettext "Email sent. Open the link provided in this browser.")
          |> redirect(to: "/ibgib/#{src_ib_gib}")

        {:error, reason} ->
          _ = Logger.error reason
          friendly_emsg = dgettext "error", @emsg_email_send_failed
          conn
          |> put_flash(:error, friendly_emsg)
          |> redirect(to: "/ibgib/#{src_ib_gib}")
      end
    else
      _ = Logger.debug "ident is INVALID. email_addr: #{email_addr}"
      friendly_emsg = dgettext "error", @emsg_invalid_email
      conn
      |> put_flash(:error, friendly_emsg)
      |> redirect(to: "/ibgib/#{src_ib_gib}")
    end
  end
  # At this point, the user has clicked on the link and entered the pin.
  def ident(conn, %{"token" => token, "ident_pin" => ident_pin} = params)
    when is_bitstring(token) and is_bitstring(ident_pin) do
    Logger.metadata(x: :ident_email_login_token)
    Logger.warn "Hey, we have a token and an ident_pin.\ntoken: #{token}\nident_pin: #{ident_pin}"
    Logger.info "conn: #{inspect conn}"

    case complete_email_impl(conn, token, ident_pin) do
      {:ok, {conn, email_addr, src_ib_gib}} ->
        conn
        |> put_flash(:info, gettext("Success! You have now added an email to your current identity. See https://github.com/ibgib/ibgib/wiki/identity for more info.") <> "\n#{email_addr}")
        |> redirect(to: "/ibgib/#{src_ib_gib}")

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
  def ident(conn, %{"token" => token} = params) do
    Logger.metadata(x: :ident_email_login_token)
    Logger.warn "Hey, we have a token"
    Logger.info "conn: #{inspect conn}"

    case continue_email_impl(conn, token) do
      # A pin was provided, so we must first confirm the pin before logging in.
      {:ok, {conn, :enter_pin}} ->
        _ = Logger.debug "enter_pin"
        conn
        |> put_flash(:info, gettext("Excellent! You're almost there. Now just enter the same pin you entered when first logging in. See https://github.com/ibgib/ibgib/wiki/identity for more info."))
        |> render("enterpin.html")

      # No pin is used so skip it and go directly to logging in.
      {:ok, {conn, :skip_pin}} ->
        ident(conn, %{"token" => token, "ident_pin" => ""})

      # Oops
      {:error, reason} ->
        _ = Logger.error reason
        friendly_emsg = dgettext("error", @emsg_ident_email_failed)
        conn
        |> put_flash(:error, friendly_emsg)
        |> redirect(to: "/ibgib/#{@root_ib_gib}")
    end
  end
  def ident(conn, params) do
    Logger.error "Unknown ident params.\nconn:\n#{inspect conn}"
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
      e in RuntimeError -> {:error, inspect e}
    end
  end

  defp continue_email_impl(conn, token) do
    with(
      {:ok, :ok} <- check_timestamp_expiration(conn),
      # At this point, the token is in the URL, so no biggie putting in session.
      conn <- put_session(conn, @ident_email_timestamp_key, token),
      pin_provided <- get_session(conn, @ident_email_pin_provided_key),
      pin_action <- (if pin_provided == "true", do: :enter_pin, else: :skip_pin)
    ) do
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
      # :erlang.system_time(:milli_seconds) - String.to_integer(timestamp)
      :erlang.system_time(:milli_seconds) - timestamp
    if elapsed_ms <= @max_ident_elapsed_ms do
      {:ok, :ok}
    else
      {:error, @emsg_ident_email_token_expired}
    end
  end

  # If this fails at any point, the whole process must be restarted.
  # This is acceptable, since it's a (relatively) fast workflow and the
  # pin is optional. The pin is not supposed to be complicated, since it is a
  # one-time pin and is only adding a secondary layer of defense.
  defp complete_email_impl(conn, token, ident_pin) do
    _ = Logger.debug "token: #{token}\nident_pin: #{ident_pin}"
    with(
      # Gather our previous info, cleaning up as we go.
      email_addr <- get_session(conn, @ident_email_login_addr_key),
      _ <- Logger.debug("1 email_addr: #{email_addr}"),
      conn <- put_session(conn, @ident_email_login_addr_key, nil),
      _ <- Logger.debug("2"),
      src_ib_gib <- get_session(conn, @ident_email_src_ib_gib_key),
      _ <- Logger.debug("3 src_ib_gib: #{src_ib_gib}"),
      conn <- put_session(conn, @ident_email_src_ib_gib_key, nil),
      _ <- Logger.debug("4"),
      ident_pin_hash <- hash(ident_pin),
      _ <- Logger.debug("5 ident_pin_hash: #{ident_pin_hash}"),

      # Check ident_pin and token
      {:ok, token} <-
        WebGib.Data.get_ident_email_token(email_addr, ident_pin_hash)
    ) do
      {:ok, conn, email_addr, src_ib_gib}
    else
      {:error, reason} when is_bitstring(reason) -> {:error, reason}
      {:error, reason} -> {:error, inspect reason}
      error -> {:error, inspect error}
    end
  end

  # ----------------------------------------------------------------------------
  # Helper
  # ----------------------------------------------------------------------------

  defp validate(type, instance)
  defp validate(:dest_ib, dest_ib) do
    valid_ib?(dest_ib) or
      # empty or nil dest_ib will be set automatically.
      dest_ib === "" or dest_ib === nil
  end
  defp validate(:comment_text, comment_text) when is_bitstring(comment_text) do
    # Right now, I don't really care what text is in there. Will need to do
    # fancier validation later obviously. But I'm not too concerned with text
    # length at the moment, just so long as it is less than the allowed data
    # size.
    _ = Logger.warn "comment_text: #{comment_text}"
    _ = Logger.warn "string length comment_text: #{String.length(comment_text)}"
    _ = Logger.warn "@max_comment_text_size: #{@max_comment_text_size}"

    String.length(comment_text) < @max_comment_text_size
  end
  defp validate(:comment_text, comment_text) do
    _ = Logger.warn "Invalid comment_text: #{inspect comment_text}"
    false
  end
  defp validate(:pic_data, {content_type, filename, path}) do
    _ = Logger.warn "validating pic_data..."
    !!content_type and !!filename and !!path and File.exists?(path)
  end
  defp validate(:link_text, link_text) when is_bitstring(link_text) do
    _ = Logger.warn "link_text: #{link_text}"

    # Just check the bare minimum right now.
    link_text_length = String.length(link_text)
    link_text_length >= @min_link_text_size and
      link_text_length <= @max_link_text_size
  end
  defp validate(:link_text, link_text) do
    _ = Logger.warn "Invalid link_text: #{inspect link_text}"
    false
  end
  defp validate(:email_addr, email_addr) when is_bitstring(email_addr) do
    _ = Logger.warn "email_addr: #{email_addr}"

    # Just check the bare minimum right now.
    email_addr_length = String.length(email_addr)
    valid =
      email_addr_length >= @min_email_addr_size and
      email_addr_length <= @max_email_addr_size and
      Regex.match?(@regex_valid_email_addr, email_addr)
  end
  defp validate(:email_addr, email_addr) do
    _ = Logger.warn "Invalid email_addr: #{inspect email_addr}"
    false
  end
  defp validate(:ib_gib, ib_gib) when is_bitstring(ib_gib) do
    Logger.info "valid_ib_gib?: #{valid_ib_gib?(ib_gib)}"
    valid_ib_gib?(ib_gib)
  end
  defp validate(:ib_gib, ib_gib) do
    Logger.info "Invalid ib_gib: #{inspect ib_gib}"
    false
  end

end
