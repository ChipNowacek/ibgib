defmodule IbGib do
  use Application

  def start(_type, _args) do
    IbGib.Supervisor.start_link
  end

  # def bootstrap do
  #   {:ok, root} = IbGib.Expression.Supervisor.start_expression()
  # end
end
