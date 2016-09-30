defmodule WebGib.IbGibController do
  @moduledoc """
  Controller related to ib_gib code.
  """

  # ----------------------------------------------------------------------------
  # Usings, imports, etc.
  # ----------------------------------------------------------------------------

  use IbGib.Constants, :validation
  use WebGib.Web, :controller

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
    # |> redirect()
    # |> render("index.html")
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
    _ = Logger.debug "JSON get. conn: #{inspect conn}"
    _ = Logger.debug "JSON get. params: #{inspect params}"
    _ = Logger.error @emsg_invalid_ibgib_url
    json(conn, %{error: @emsg_invalid_ibgib_url})
  end

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
    _ = Logger.warn ""

    _ = Logger.warn "@root_ib_gib: #{@root_ib_gib}"

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
      {:ok, bin_id} <- save_to_bin_store(path),
      {:ok, pic} <-
        pic
        |> Expression.mut8(identity_ib_gibs,
                           %{
                             "content_type" => content_type,
                             "filename" => filename,
                             "bin_id" => bin_id
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

  defp save_to_bin_store(path) do
    with(
      {:ok, body} <- File.read(path),
      bin_data <- IO.iodata_to_binary(body),
      :ok <- :ok
    ) do
      {:ok, "ok"}
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
  defp validate(:ib_gib, ib_gib) when is_bitstring(ib_gib) do
    Logger.info "valid_ib_gib?: #{valid_ib_gib?(ib_gib)}"
    valid_ib_gib?(ib_gib)
  end
  defp validate(:ib_gib, ib_gib) do
    Logger.info "Invalid ib_gib: #{inspect ib_gib}"
    false
  end

end
