defmodule IbGib.Macros do

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
