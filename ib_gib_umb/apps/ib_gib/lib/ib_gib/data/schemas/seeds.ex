defmodule IbGib.Data.Schemas.Seeds do
  require Logger
  use IbGib.Constants, :ib_gib
  alias IbGib.Data.Repo
  alias IbGib.Data.Schemas.IbGibModel

  def get_seed(:root) do
    %IbGibModel{
      :ib => "ib",
      :gib => "gib",
      :rel8ns => %{
        "dna" => ["ib#{delim}gib"],
        "ancestor" => ["ib#{delim}gib"],
        },
      :data => %{}
    }
  end
  def get_seed(:fork), do: get_seed("fork")
  def get_seed(:mut8), do: get_seed("mut8")
  def get_seed(:rel8), do: get_seed("rel8")
  def get_seed(:query), do: get_seed("query")
  def get_seed(ib_string) when is_bitstring(ib_string) do
    Logger.debug "getting seed ib_gib #{ib_string} expression."
    %IbGibModel{
      :ib => ib_string,
      :gib => "gib",
      :rel8ns => %{
        "dna" => ["ib#{delim}gib", "ib#{delim}gib"],
        "ancestor" => ["ib#{delim}gib"],
        },
      :data => %{}
    }
  end
end
