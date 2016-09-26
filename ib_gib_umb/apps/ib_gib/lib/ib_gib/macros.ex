defmodule IbGib.Macros do
  @moduledoc """
  Contains common macros used across the application.

  Right now it's just one macro: the `bang` macro.
  Thanks http://elixir-recipes.github.io/metaprogramming/bang-macro/
  """

  # Creates bang case statement
  defmacro bang(result) do
    quote do
      case unquote(result) do
        {:ok, value} -> value
        {:error, error} when is_bitstring(error) -> raise error
        {:error, error} -> raise inspect error
      end
    end
  end

  defmacro invalid_args(args) do
    quote do
      emsg = emsg_invalid_args(unquote(args))
      Logger.error emsg
      {:error, emsg}
    end
  end
end
