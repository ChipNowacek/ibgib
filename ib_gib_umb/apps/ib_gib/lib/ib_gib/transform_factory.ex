defmodule IbGib.TransformFactory do
  alias IbGib.Helper

  @doc """
  Creates a fork with source ib of "ib" and dest_ib of given `dest_ib`.
  """
  @spec fork(String.t, String.t) :: map
  def fork(src_ib_gib \\ "ib|gib", dest_ib \\ Helper.new_id) do

    data = %{src_ib_gib: src_ib_gib, dest_ib: dest_ib}
    gib = Helper.hash(data)
    %{
      ib: "fork",
      gib: gib,
      ib_gib: ["ib_gib", "fork_gib"],
      data: data
    }
  end

end
