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
        {:error, error} -> raise error
      end
    end
  end

end
