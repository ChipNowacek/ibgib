defmodule IbGib.Data do
  require Logger
  import Ecto.Query

  alias IbGib.Data.Schemas.IbGibModel
  alias IbGib.Data.Repo

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

  Returns `{:ok, :ok}` if succeeds **or if the ib+gib already exists**. It will
  log the fact that it tried to save data that already existed. If fails,
  returns `{:error, reason}`
  """
  def save(info) when is_map(info) do
    # I can't figure out how to do a multi-line with clause!
    with {:ok, _model} <- insert_into_repo(info),
         {:ok, :ok}    <- IbGib.Data.Cache.put(IbGib.Helper.get_ib_gib!(info[:ib], info[:gib]), info) do
        {:ok, :ok}
    else
      # Need to improve this. :X
      {:error, :already} ->
        Logger.info "Tried to save info data that already exists."
        {:ok, :ok}
      # {:error, changeset} ->
      #   {:error, "Save failed. changeset: #{inspect changeset}"}
      failure -> {:error, "Save failed: #{inspect failure}"}
    end
  end

  @doc """
  Bang version of `save/1`.
  """
  def save!(info) when is_map(info) do
    Logger.warn "info: #{inspect info}"
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
  def load(ib, gib) when is_bitstring(ib) and is_bitstring(gib) do
    key = IbGib.Helper.get_ib_gib!(ib, gib)
    # For now, simply gets the value from the cache
    case IbGib.Data.Cache.get(key) do
      {:ok, value} -> {:ok, value}
      {:error, _} -> get_from_repo(ib, gib)
    end
  end

  @doc """
  Bang version of `load/2`.
  """
  def load!(ib, gib) when is_bitstring(ib) and is_bitstring(gib) do
    case load(ib, gib) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  @doc """
  ib_options:
    keys: "regex", "is", "in"
    value: bitstring, e.g. "some ib", "[A-Za-z0]+"
  """
  def query(%{"ib" => ib_options, "data" => data_options, "rel8ns" => rel8ns_options, "time" => time_options, "meta" => meta_options} = options) do

    # Run options are passed between functions
    # Use case for putting them in is attempting to do a lateral select
    # when needed (e.g. when doing a `LIKE` on a jsonb map key)
    run_options = %{"select_type" => "normal", "lateral_search_term" => nil}

    {model, run_options} =
      { IbGibModel, run_options}
      |> add_ib_options(ib_options)
      |> add_data_options(data_options)
      |> add_rel8ns_options(rel8ns_options)
      |> add_time_options(time_options)
      |> add_meta_options(meta_options)
      |> select_ib_gib

    result = model |> Repo.all

    Logger.warn "data query result yo-=------------------------\n#{inspect result}"
    result
  end

  defp do_select({query, %{"select_type" => select_type, "lateral_search_term" => lateral_search_term}}) do
    case select_type do
      "normal" ->
        query = query |> select([:ib, :gib, :inserted_at])
        {query, run_options}
      "lateral_data" ->
        query =
          query
          |> join(:inner_lateral, [x], y in fragment("SELECT jsonb_each_text(data) WHERE key LIKE ?", "%#{^lateral_search_term}%"))
          |> select([x], x.ib, x.gib, x.inserted_at)
        {query, run_options}
    end
  end

  # ----------------------------------------------------------------------------
  # Private Functions
  # ----------------------------------------------------------------------------

  defp add_ib_options({query, run_options}, %{"what" => search_term, "how" => method} =
    ib_options)
    when is_map(ib_options) and map_size(ib_options) > 0 and
         is_bitstring(search_term) and is_bitstring(method) do
    Logger.warn "yoooooooooooooooo"

    case method do
      "is" ->
        query =
          query |> where(ib: ^search_term)
        {query, run_options}
      "like" ->
        wrapped_search_term = "%#{search_term}%"
        query =
          query |> where([x], ilike(x.ib, ^wrapped_search_term))
        {query, run_options}
      _ ->
        Logger.info("Unknown method: #{method}. search_term: #{search_term}")
        {query, run_options}
    end
  end
  defp add_ib_options({query, run_options}, ib_options) do
    {query, run_options}
  end

  defp add_data_options({query, run_options}, %{"what" => search_term, "how" => method,
    "where" => where} = data_options)
    when is_map(data_options) and map_size(data_options) > 0 and
         is_bitstring(search_term) and is_bitstring(method) and
         is_bitstring(where) do
    Logger.warn "yoooooooooooooooo"

    case {where, method} do
      {"key", "is"} ->
        Logger.warn "key is"
        query =
          query
          |> where([x], fragment("? \\? ?", x.data, ^search_term))
        {query, run_options}
      {"key", "like"} ->
        Logger.warn "key like"
        run_options = Map.merge(run_options, %{})
      _ ->
        Logger.info("Unknown {method, where}: {#{method}, #{where}}. search_term: #{search_term}")
        {query, run_options}
    end
  end
  defp add_data_options({query, run_options}, data_options) do
    {query, run_options}
  end

  defp add_rel8ns_options({query, run_options}, rel8ns_options) when is_map(rel8ns_options) and map_size(rel8ns_options) > 0 do
    {query, run_options}
  end
  defp add_rel8ns_options({query, run_options}, rel8ns_options) do
    {query, run_options}
  end

  defp add_time_options({query, run_options}, time_options) when is_map(time_options) and map_size(time_options) > 0 do
    {query, run_options}
  end
  defp add_time_options({query, run_options}, time_options) do
    {query, run_options}
  end

  defp add_meta_options({query, run_options}, meta_options) when is_map(meta_options) and map_size(meta_options) > 0 do
    {query, run_options}
  end
  defp add_meta_options({query, run_options}, meta_options) do
    {query, run_options}
  end

  @doc """
  Inserts ib_gib info into the repo.

  Returns {:ok, model} or {:error, changeset}
  """
  defp insert_into_repo(info) when is_map(info) do
    Logger.debug "inserting into repo. info: #{inspect info}"
    case IbGibModel.changeset(%IbGibModel{}, %{
           ib: info[:ib],
           gib: info[:gib],
           data: info[:data],
           rel8ns: info[:rel8ns]
         })
         |> Repo.insert do

      {:ok, model} ->
        Logger.warn "Inserted changeset.\nib: #{info[:ib]}\ngib: #{info[:gib]}\nmodel: #{inspect model}"
        {:ok, model}

      {:error, changeset} ->
        already_error = {"has already been taken", []}
        if (Enum.count(changeset.errors) === 1 and changeset.errors[:ib] === already_error) do
          Logger.warn "Did NOT insert changeset. Already exists.\nib: #{info[:ib]}\ngib: #{info[:gib]}\nchangeset: #{inspect changeset}"
          {:error, :already}
        else
          Logger.error "Error inserting changeset.\nib: #{info[:ib]}\ngib: #{info[:gib]}\nchangeset: #{inspect changeset}"
          {:error, changeset}
        end
    end
  end

  defp get_from_repo(ib, gib) do
    model =
      IbGibModel
      |> where(ib: ^ib, gib: ^gib)
      |> Repo.one

    Logger.warn "got model: #{inspect model}"
    if (model === nil) do
      {:error, :not_found}
    else
      %{:ib => ^ib, :gib => ^gib, :data => data, :rel8ns => rel8ns} = model
      {:ok, %{:ib => ib, :gib => gib, :data => data, :rel8ns => rel8ns}}
    end
  end
end
