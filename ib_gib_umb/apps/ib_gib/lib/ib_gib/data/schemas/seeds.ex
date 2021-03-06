defmodule IbGib.Data.Schemas.Seeds do
  @moduledoc """
  Utility functions to aid seeding repo.
  """

  require Logger

  use IbGib.Constants, :ib_gib
  alias IbGib.Data.Repo
  alias IbGib.Data.Schemas.IbGibModel


  @doc """
  Redeclared as helper for .exs file
  """
  def delim, do: @delim
  @doc """
  Redeclared as helper for .exs file
  """
  def root_ib_gib, do: @root_ib_gib
  @doc """
  Redeclared as helper for .exs file
  """
  def default_rel8ns, do: @default_rel8ns

  # Specifiers allow for basic "inheritance" creation.
  # Use case: I want a "text^gib", from which "comment^gib", "url^gib", etc.,
  #           will descend.
  # (I wanted to do all of this manually in the db, but it's just simpler to do
  # it here.)
  @specifiers [:text_child, :binary_child, :tag_child]

  def insert(ib_atom, data \\ %{})
  def insert(ib_atom, data)
    when is_atom(ib_atom) and is_map(data) do
    ib = Atom.to_string(ib_atom)
    _ = Logger.info "Inserting #{ib}..."
    try do
      case Repo.insert(get_seed(ib_atom)) do
        {:ok, _struct} -> _ = Logger.warn "Inserted #{ib} successfully."
        {:error, error} -> _ = Logger.error "Insert #{ib} failed. Already seeded? error: #{inspect error}"
      end
    rescue
      error -> _ = Logger.error "Insert #{ib} failed. Already seeded? error: #{inspect error}"
    end
    :ok
  end
  def insert({ib_atom, specifier}, _data)
    when is_atom(ib_atom) and is_atom(specifier) and
         (specifier in @specifiers) do
    ib = Atom.to_string(ib_atom)
    Logger.info "Inserting #{ib}..."
    try do
      case Repo.insert(get_seed({ib, specifier})) do
        {:ok, _struct} -> _ = Logger.warn "Inserted #{ib} successfully."
        {:error, error} -> _ = Logger.error "Insert #{ib} failed. error: #{inspect error}"
      end
    rescue
      error -> _ = Logger.error "Insert #{ib} failed. error: #{inspect error}"
    end
    :ok
  end

  def get_seed(ib_atom, data \\ %{})
  def get_seed(ib_atom, data)
    when is_atom(ib_atom) and ib_atom != :root do
    get_seed(Atom.to_string(ib_atom), data)
  end
  def get_seed(ib_string, data)
    when is_bitstring(ib_string) and is_map(data) do
    _ = Logger.debug "getting seed ib_gib #{ib_string} expression."
    %IbGibModel{
      ib: ib_string,
      gib: "gib",
      rel8ns: %{
        "dna" => @default_dna,
        "ancestor" => @default_ancestor,
        "past" => @default_past,
        "identity" => @default_identity
        },
      data: data
    }
  end
  def get_seed(:root, data) do
    %IbGibModel{
      ib: "ib",
      gib: "gib",
      rel8ns: %{
        "dna" => @default_dna,
        "ancestor" => @default_ancestor,
        "past" => @default_past,
        "identity" => @default_identity
        },
      data: data
    }
  end
  # This overload is for generating seeds that "descend" (forked from) text^gib.
  def get_seed({ib_string, :text_child}, data) do
    _ = Logger.debug "get_seed :text_child. ib_string: #{ib_string}"
    %IbGibModel{
      ib: ib_string,
      gib: "gib",
      rel8ns: %{
        "dna" => @default_dna,
        "ancestor" => @default_ancestor ++ ["text#{@delim}gib"],
        "past" => @default_past,
        "identity" => @default_identity
        },
      data: data
    }
  end
  # This overload is for generating seeds that "descend" (forked from) text^gib.
  def get_seed({ib_string, :binary_child}, data) do
    _ = Logger.debug "get_seed :binary_child. ib_string: #{ib_string}"
    %IbGibModel{
      ib: ib_string,
      gib: "gib",
      rel8ns: %{
        "dna" => @default_dna,
        "ancestor" => @default_ancestor ++ ["binary#{@delim}gib"],
        "past" => @default_past,
        "identity" => @default_identity
        },
      data: data
    }
  end
  # This overload is for generating seeds that "descend" (forked from) tag^gib.
  def get_seed({ib_string, :tag_child}, data) do
    _ = Logger.debug "get_seed :tag_child. ib_string: #{ib_string}"
    %IbGibModel{
      ib: ib_string,
      gib: "gib",
      rel8ns: %{
        "dna" => @default_dna,
        "ancestor" => @default_ancestor ++ ["tag#{@delim}gib"],
        "past" => @default_past,
        "identity" => @default_identity
        },
      data: data
    }
  end
end
