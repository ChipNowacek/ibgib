ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(IbGib.Data.Repo, :manual)

defmodule IbGib.TestHelper do
  use ExUnit.Case
  alias IbGib.Data.Repo

  # Helper method for validations that are expected to fail for a given
  # `changeset`.
  def flunk_insert(changeset, field, expected_validation_msg) do
    case Repo.insert(changeset) do
      {:ok, _model}        ->
        flunk("Insert succeeded but should have failed.")
      {:error, changeset} ->
        error_map = Enum.into(changeset.errors, %{})

        if (expected_validation_msg != nil) do
          {_atom, result} = Map.fetch(error_map, field)
          # IO.puts "error_map"
          # IO.inspect error_map
          # IO.puts "atom, result"
          # IO.inspect {atom, result}
          case result do
            {err_msg, _type} -> assert err_msg === expected_validation_msg
            err_msg -> assert err_msg === expected_validation_msg
          end
        end
    end
  end

  def succeed_insert(changeset) do
    case Repo.insert(changeset) do
      {:ok, _model}        ->
        nil
      {:error, changeset} ->
        IO.inspect changeset
        flunk("Insert failed but should have succeeded.")
    end
  end
end
