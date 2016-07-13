defmodule IbGib.TransformFactory do
  alias IbGib.Helper

  @delim "^"

  @doc """
  Creates a fork with source ib of "ib" and dest_ib of given `dest_ib`.
  """
  @spec fork(String.t, String.t) :: map
  def fork(src_ib_gib \\ "ib#{@delim}gib", dest_ib \\ Helper.new_id) do
    ib = "fork"
    ib_gib_history = ["ib#{@delim}gib", "fork#{@delim}gib"]
    data = %{src_ib_gib: src_ib_gib, dest_ib: dest_ib}
    gib = Helper.hash(ib, ib_gib_history, data)
    %{
      ib: ib,
      gib: gib,
      ib_gib_history: ib_gib_history,
      data: data
    }
  end

end
