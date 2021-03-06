defmodule IbGib.Data do
  @moduledoc """
  This acts as a data layer abstraction. Here you can `save/1`, `load/1`, and `query/1`
  data.

  This also contains the dynamic query implementation. So it takes a query
  information object and actually performs the query of the data.
  See `query/1` for more details.
  """
  require Logger
  import Ecto.Query

  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  alias IbGib.Data.Schemas.{IbGibModel, BinaryModel}
  alias IbGib.Data.Repo
  alias IbGib.Helper

  @doc """
  Takes the given `info`, validates it, inserts it in the repo, and then puts
  it in the cache. The `info` should be `IbGib.Data.Schemas.IbGibModel` info,
  which ATOW (9:30 AM) is as follows:

  ```
  field :ib, :string
  field :gib, :string
  field :data, :map
  field :rel8ns, :map
  ```

  _(J/k. ATOW: 2016/08/04)_
  
  2017/01/26 I'm now changing this to not care if we're trying to save 
  duplicates. This should only error on some other reason. 
  See https://elixirforum.com/t/avoiding-ecto-postgrex-logging-unique-constraint-failure/3419/3

  Returns `{:ok, :ok}` if succeeds **or if the ib+gib already exists**. It will
  log the fact that it tried to save data that already existed. If fails,
  returns `{:error, reason}`
  """
  @spec save(map) :: {:ok, :ok} | {:error, any()}
  def save(info) when is_map(info) do
    with(
      {:ok, exists} <- exists?(info[:ib], info[:gib]),
      {:ok, _model} <- insert_into_repo({exists, info}),
      {:ok, ib_gib} <- Helper.get_ib_gib(info[:ib], info[:gib]),
      {:ok, :ok} <- IbGib.Data.Cache.put(ib_gib, info)
    ) do
      {:ok, :ok}
    else
      {:error, :already} ->
        Logger.debug "Tried to save info data that already exists."
        {:ok, :ok}

      failure -> {:error, "Save failed: #{inspect failure}"}
    end
  end

  @doc """
  Bang version of `save/1`.
  """
  def save!(info) when is_map(info) do
    _ = Logger.debug "info: #{inspect info}"
    case save(info) do
      {:ok, :ok} -> :ok
      {:error, reason} -> raise reason
    end
  end

  @doc """
  This gets a map from the `IbGib.Data.Schemas.IbGibModel` for the given `ib`
  and `gib`. **Does NOT get the model struct!**

  First it looks in the `IbGib.Data.Cache`. If it's not found there, then it
  looks in the `IbGib.Data.Repo`.

  Returns the **map** of the `IbGib.Data.Schemas.IbGibModel` if found in
  either the cache or the repo, `{:ok, map}`. If not found, `{:error, :not_found}`.
  """
  @spec load(String.t, String.t) :: {:ok, any} | {:error, any}
  def load(ib, gib) when is_bitstring(ib) and is_bitstring(gib) do
    key = IbGib.Helper.get_ib_gib!(ib, gib)
    # For now, simply gets the value from the cache
    case IbGib.Data.Cache.get(key) do
      {:ok, value} -> {:ok, value}
      {:error, _} -> get_from_repo(:ibgib, {ib, gib})
    end
  end

  @doc """
  Bang version of `load/2`.
  """
  @spec load!(String.t, String.t) :: any
  def load!(ib, gib) when is_bitstring(ib) and is_bitstring(gib) do
    case load(ib, gib) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  @spec exists?(String.t, String.t) :: {:ok, true|false} | {:error, String.t}
  def exists?(ib, gib) when is_bitstring(ib) and is_bitstring(gib) do
    datum_or_nil = 
      IbGibModel 
      |> where(ib: ^ib, gib: ^gib)
      |> select([:id])
      |> Repo.one()
      
    result = if datum_or_nil, do: true, else: false
    
    {:ok, result}
  end

  @doc """
  This takes a query `info` map, converts that information into an actual
  query, using the pipe (`|>`) operator, and performs the query. This will
  always return a unique array of `IbGib.Data.Schemas.IbGibModel`.

  See `IbGib.QueryOptionsFactory` for individual options.
  """
  @spec query(map) :: any
  def query(info) do
    _ = Logger.debug "query yo. info: #{inspect info}"

    models_array =
      info
      |> Enum.reduce([], fn({i, query_opts}, acc) ->
        _ = Logger.debug "iteration number: #{i}"
        iter_result = query_iteration(query_opts)
        acc ++ iter_result
      end)
      |> Enum.uniq_by(&(&1.ib <> &1.gib))
      # |> Enum.sort(&(&1.inserted_at < &2.inserted_at))

    _ = Logger.debug "models_array: #{inspect models_array}"
    models_array
  end

  # def get_ib_gib(_ib_gib) do
  #   get_from_repo(:ibgib, :ibgib)
  # end

  # ----------------------------------------------------------------------------
  # Private Functions
  # ----------------------------------------------------------------------------

  defp query_iteration(%{"ib" => ib_options, "gib" => gib_options, "data" => data_options, "rel8ns" => rel8ns_options, "time" => time_options, "meta" => meta_options}) do
    _ = Logger.debug "query iteration yo"

    model =
      IbGibModel
      |> add_ib_options(ib_options)
      |> add_gib_options(gib_options)
      |> add_data_options(data_options)
      |> add_rel8ns_options(rel8ns_options)
      |> add_time_options(time_options)
      |> add_meta_options(meta_options)
      # |> select([:ib, :gib, :inserted_at, :data]) # why include data? debug?
      |> select([:ib, :gib, :inserted_at])

    result = model |> Repo.all

    # _ = Logger.debug "data query result yo-=------------------------\n#{inspect result}"
    # result is an array of IbGibModel structs
    result
  end

  # Options is a map of maps. Each internal map is itself a where clause
  # description.
  defp add_ib_options(query, %{"what" => search_term, "how" => method} =
    ib_options)
    when is_map(ib_options) and map_size(ib_options) > 0 and
         is_bitstring(search_term) and is_bitstring(method) do
    _ = Logger.debug "adding ib_options: #{inspect ib_options}"

    case method do
      "is" ->
        query =
          query |> where(ib: ^search_term)
        query
      "isnt" ->
        query =
          query |> where(fragment("ib != ?", ^search_term))
        query
      "like" ->
        wrapped_search_term = wrap_if_needed(search_term)
        query =
          query |> where([x], ilike(x.ib, ^wrapped_search_term))
        query
      _ ->
        Logger.info("Unknown method: #{method}. search_term: #{search_term}")
        query
    end
  end
  defp add_ib_options(query, _) do
    query
  end

  defp add_gib_options(query, %{"what" => search_term, "how" => method} =
    gib_options)
    when is_map(gib_options) and map_size(gib_options) > 0 and
         is_bitstring(search_term) and is_bitstring(method) do

    case method do
      "is" ->
        query =
          query |> where(gib: ^search_term)
        query
      "isnt" ->
        query =
          query |> where(fragment("gib != ?", ^search_term))
        query
      "like" ->
        wrapped_search_term = wrap_if_needed(search_term)
        query =
          query |> where([x], ilike(x.gib, ^wrapped_search_term))
        query
      _ ->
        Logger.info("Unknown method: #{method}. search_term: #{search_term}")
        query
    end
  end
  defp add_gib_options(query, _) do
    query
  end

  defp add_data_options(query, %{"what" => search_term, "how" => method,
    "where" => where} = data_options)
    when is_map(data_options) and map_size(data_options) > 0 and
         is_bitstring(search_term) and is_bitstring(method) and
         is_bitstring(where) do
    _ = Logger.debug "yoooooooooooooooo"

    case {where, method} do
      {"key", "is"} ->
        _ = Logger.debug "key is"
        query =
          query
          |> where([x], fragment("? \\? ?", x.data, ^search_term))
        query
      {"key", "like"} ->
        _ = Logger.debug "key like"
        wrapped_search_term = wrap_if_needed(search_term)
        query =
          query
          |> where(fragment("(SELECT count(*) FROM jsonb_each_text(data) WHERE key ILIKE ?) > 0", ^wrapped_search_term))
        query
      {"value", "is"} ->
        _ = Logger.debug "value is"
        query =
          query
          |> where(fragment("(SELECT count(*) FROM jsonb_each_text(data) WHERE value = ?) > 0", ^search_term))
        query
      {"value", "like"} ->
        _ = Logger.debug "key like"
        wrapped_search_term = wrap_if_needed(search_term)
        query =
          query
          |> where(fragment("(SELECT count(*) FROM jsonb_each_text(data) WHERE value ILIKE ?) > 0", ^wrapped_search_term))
        query
      _ ->
        Logger.info("Unknown {method, where}: {#{method}, #{where}}. search_term: #{search_term}")
        query
    end
  end
  defp add_data_options(query, _) do
    query
  end

  # This allows multiple ANDed clauses.
  defp add_rel8ns_options(query, rel8ns_options)
  defp add_rel8ns_options(query, rel8ns_options)
    when is_map(rel8ns_options) and map_size(rel8ns_options) > 0 do
    rel8ns_options
    |> Enum.reduce(query, fn({_iteration, opts}, qry) ->
         add_rel8ns_options_iteration(qry, opts)
       end)
  end
  defp add_rel8ns_options(query, _) do
    query
  end

  # This overload is for is_bitstring(search_term)
  # "where" is the rel8n_name in this case
  
  
  defp add_rel8ns_options_iteration(query, %{"what" => search_term, "how" =>
    method, "where" => where, "extra" => with_or_without} = rel8ns_options)
    when is_map(rel8ns_options) and map_size(rel8ns_options) > 0 and
         is_bitstring(search_term) and is_bitstring(method) and
         is_bitstring(where) and is_bitstring(with_or_without)do
      case {with_or_without, method} do

        # rel8ns is in form of {rel8ns: {"rel1": [a,b,c]}, {"rel2": [b,c,d], ...}}
        # It may be tricky to wrap your head around.
        # Here are the different parts of the following 2 where clauses:
        # rel8ns -> ?   says pull the array (e.g. [a,b,c]) for rel8n `?`
        # SELECT jsonb_array_elements_text     makes the array usable with `IN` / `NOT IN`
        # ? IN array    says is search term in that array, e.g. "a" IN [a,b,c]
        {"with", "ibgib"} ->
          _ = Logger.debug "with ib_gib. where: #{where}. search_term: #{search_term}"
          query
          |> where(fragment("? IN (SELECT jsonb_array_elements_text(rel8ns -> ?))", ^search_term, ^where))

        {"without", "ibgib"} ->
          _ = Logger.debug "with ib_gib. where: #{where}. search_term: #{search_term}"
          query
          |> where(fragment("? NOT IN (SELECT jsonb_array_elements_text(rel8ns -> ?))", ^search_term, ^where))


        {"with", "ib"} ->
          _ = Logger.debug "with ib. where: #{where}. search_term: #{search_term}"
          # regex ^[^^]+ means from the start of the ib^gib up until the ^ delim
          query
          |> where(fragment("? IN (SELECT substring( jsonb_array_elements_text(rel8ns -> ?) FROM '^[^^]+'))", ^search_term, ^where))

        # not going to worry about implementing this right now since low
        # priority
        # {"without", "ib"} ->
        #   _ = Logger.debug "with ib. where: #{where}. search_term: #{search_term}"
        #   regex = ""
        #   query
        #   |> where(fragment("? NOT IN (SELECT substring( jsonb_array_elements_text(rel8ns -> ?) FROM '^[^^]+'))", ^search_term, ^where))

        _ ->
          _ = Logger.warn "unknown {with_or_without, method}: {#{with_or_without}, #{method}}"
          query
      end
  end
  # This overload is for is_list(search_term)
  defp add_rel8ns_options_iteration(query, %{"what" => search_term, "how" =>
    method, "where" => where, "extra" => with_or_without} = rel8ns_options)
    when is_map(rel8ns_options) and map_size(rel8ns_options) > 0 and
         is_list(search_term) and is_bitstring(method) and
         is_bitstring(where) and is_bitstring(with_or_without)do

      _ = Logger.debug "add_rel8ns_options_iteration with search_term as list"

      case {with_or_without, method} do

        {"withany", "ibgib"} ->
          _ = Logger.debug "with ib_gib. where: #{where}. search_term: #{search_term}"
          query
          |> where(
               fragment(
                 "? && ARRAY(SELECT jsonb_array_elements_text(rel8ns -> ?))", ^search_term, ^where
               )
             )

        _ ->
          _ = Logger.warn "unknown {with_or_without, method}: {#{with_or_without}, #{method}}"
          query
      end
  end
  defp add_rel8ns_options_iteration(query, opts) do
    _ = Logger.warn "unknown rel8ns options: #{inspect opts}"
    query
  end

  defp add_time_options(query, %{"how" => how} = time_options)
    when is_map(time_options) and map_size(time_options) > 0 and
         is_bitstring(how) and how != "" do
    case how do
      "most recent" ->
        query
        |> order_by(desc: :inserted_at)
        |> limit(1)

      _ ->
        _ = Logger.warn "unknown time option. how: #{how}"
        query
    end
  end
  defp add_time_options(query, _) do
    query
  end

  defp add_meta_options(query, meta_options) when is_map(meta_options) and map_size(meta_options) > 0 do
    query
  end
  defp add_meta_options(query, _) do
    query
  end

  # Inserts ib_gib info into the repo.
  #
  # Returns {:ok, model} or {:error, changeset}
  defp insert_into_repo({_exists = false, info}) when is_map(info) do
    _ = Logger.debug "inserting into repo. info: #{inspect info}"
    insert_result =
      %IbGibModel{}
      |> IbGibModel.changeset(%{
           ib: info[:ib],
           gib: info[:gib],
           data: info[:data],
           rel8ns: info[:rel8ns]
         })
     |> Repo.insert
    case insert_result do
      {:ok, model} ->
        _ = Logger.debug "Inserted changeset.\nib: #{info[:ib]}\ngib: #{info[:gib]}\nmodel: #{inspect model}"
        {:ok, model}

      {:error, changeset} ->
        already_error = {"has already been taken", []}
        if Enum.count(changeset.errors) == 1 and
           changeset.errors[:ib] == already_error do
          _ = Logger.debug "Did NOT insert changeset. Already exists.\nib: #{info[:ib]}\ngib: #{info[:gib]}\nchangeset: #{inspect changeset}"
          {:error, :already}
        else
          _ = Logger.error "Error inserting changeset.\nib: #{info[:ib]}\ngib: #{info[:gib]}\nchangeset: #{inspect changeset}"
          {:error, changeset}
        end
    end
  end
  defp insert_into_repo({_exists = true, info}) do
    _ = Logger.debug("skipping insert into repo, info already exists. ib^gib: #{Helper.get_ib_gib!(info)}")
    {:ok, nil}
  end
  # defp insert_into_repo({binary_id, binary_data})
  #   when is_bitstring(binary_id) and is_binary(binary_data) do
  #     _ = Logger.debug "inserting into repo. binary_id: #{binary_id}"
  #     insert_result =
  #       %BinaryModel{}
  #       |> BinaryModel.changeset(%{
  #            binary_id: binary_id,
  #            binary_data: binary_data
  #          })
  #      |> Repo.insert
  #     case insert_result do
  #       {:ok, model} ->
  #         _ = Logger.debug "Inserted changeset.\nbinary_id: #{binary_id}"
  #         {:ok, model}
  # 
  #       {:error, changeset} ->
  #         already_error = {"has already been taken", []}
  #         if Enum.count(changeset.errors) == 1 and
  #            changeset.errors[:binary_id] == already_error do
  #           _ = Logger.debug "Did NOT insert changeset. Already exists.\nbinary_id: #{binary_id}"
  #           {:error, :already}
  #         else
  #           _ = Logger.error "Error inserting changeset.\nbinary_id: #{binary_id}"
  #           {:error, changeset}
  #         end
  #     end
  # end

  defp get_from_repo(:ibgib, {ib, gib}) do
    model =
      IbGibModel
      |> where(ib: ^ib, gib: ^gib)
      |> Repo.one

    _ = Logger.debug "got model: #{inspect model}"
    if model == nil do
      {:error, :not_found}
    else
      %{:ib => ^ib, :gib => ^gib, :data => data, :rel8ns => rel8ns} = model
      
      {:ok, %{:ib => ib, :gib => gib, :data => data, :rel8ns => rel8ns}}
    end
  end
  # defp get_from_repo(:ibgib, :ibgib) do
  #   _ = Logger.warn("get_from_repo called...whooooa")
  #   result = 
  #     IbGibModel 
  #     |> order_by(asc: :inserted_at)
  #     |> Repo.all()
  #     |> Enum.map(fn(item) -> 
  #          %{
  #             :ib => item.ib, 
  #             :gib => item.gib, 
  #             :data => item.data, 
  #             :rel8ns => item.rel8ns
  #           } 
  #        end)
  #   
  #   _ = Logger.warn("get_from_repo result count: #{Enum.count(result)}")
  #   
  #   {:ok, result}
  # end
  # defp get_from_repo(:binary, binary_id) do
  #   model =
  #     BinaryModel
  #     |> where(binary_id: ^binary_id)
  #     |> Repo.one
  # 
  #     if model == nil do
  #       {:error, :not_found}
  #     else
  #       {:ok, %{:binary_id => binary_id, :binary_data => model.binary_data}}
  #     end
  # end


  # Wraps the search_term in `%`s for use with LIKE clauses, but only if it
  # doesn't already contain a `%` sign.
  defp wrap_if_needed(search_term) do
    if String.contains?(search_term, "%") do
      search_term
    else
      "%#{search_term}%"
    end
  end
end
