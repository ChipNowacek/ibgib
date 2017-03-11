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
        error -> raise inspect error
      end
    end
  end

  defmacro invalid_args(args) do
    quote do
      emsg = emsg_invalid_args(unquote(args))
      _ = Logger.error emsg
      {:error, emsg}
    end
  end
  
  @doc """
  Having this as a macro keeps the logged error line correct.
  """
  defmacro handle_ok_error(untagged_reason, opts) do
    quote do
      reason = case unquote(untagged_reason) do
        reason when is_bitstring(reason) -> reason
        reason when is_atom(reason) -> Atom.to_string(reason)
        reason -> inspect reason
      end
      if unquote(opts[:log]), do: Logger.error reason
      reason
    end
  end
  
  defmacro handle_ok_error(untagged_reason) do
    quote do 
      handle_ok_error(unquote(untagged_reason), [])
    end
  end
end
