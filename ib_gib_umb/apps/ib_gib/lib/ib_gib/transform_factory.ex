defmodule IbGib.TransformFactory do
  alias RandomGib.Get

  @spec fork(String.t) :: map
  def fork(dest_id \\ new_id) do
    %{
      name: "fork",
      dest_id: dest_id
    }
  end

  def new_id() do
    RandomGib.Get.some_letters(30)
  end
end
