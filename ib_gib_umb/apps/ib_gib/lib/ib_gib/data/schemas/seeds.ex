defmodule IbGib.Data.Schemas.Seeds do
  @moduledoc """
  Utility functions to aid seeding ecto db.
  """
  
  require Logger
  use IbGib.Constants, :ib_gib
  alias IbGib.Data.Repo
  alias IbGib.Data.Schemas.IbGibModel


  def insert(ib_atom) when is_atom(ib_atom) do
    ib = Atom.to_string(ib_atom)
    Logger.info "Inserting #{ib}..."
    try do
      case Repo.insert(get_seed(ib_atom)) do
        {:ok, _struct} -> Logger.warn "Inserted #{ib} successfully."
        {:error, changeset} -> Logger.error "Insert #{ib} failed. changeset: #{inspect changeset}"
      end
    rescue
      error -> Logger.error "Insert #{ib} failed. changeset: #{inspect error}"
    end
    :ok
  end

  def get_seed(ib_atom) when is_atom(ib_atom) and ib_atom != :root do
    get_seed(Atom.to_string(ib_atom))
  end
  def get_seed(ib_string) when is_bitstring(ib_string) do
    Logger.debug "getting seed ib_gib #{ib_string} expression."
    %IbGibModel{
      ib: ib_string,
      gib: "gib",
      rel8ns: %{
        "dna" => ["ib#{delim}gib", "ib#{delim}gib"],
        "ancestor" => ["ib#{delim}gib"],
        },
      data: %{}
    }
  end
  def get_seed(:root) do
    %IbGibModel{
      ib: "ib",
      gib: "gib",
      rel8ns: %{
        "dna" => ["ib#{delim}gib"],
        "ancestor" => ["ib#{delim}gib"],
        },
      data: %{}
    }
  end
end
