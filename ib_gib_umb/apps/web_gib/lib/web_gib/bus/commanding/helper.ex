defmodule WebGib.Bus.Commanding.Helper do
  @moduledoc """
  Helper functions for Commanding.
  """

  require Logger

  import WebGib.Validate

  # ------------------------------------------------------------------------
  # Error
  # ------------------------------------------------------------------------

  def handle_cmd_error(:error, reason, msg, socket) do
    # stub - do nothing right now :-/
    _ = Logger.error("error reason: #{inspect reason}.\nmsg: #{inspect msg}\nsocket: #{inspect socket}")
    error_msg = %{
      "errors" => [
        %{
          "id" => "General Gibberish",
          "title" => "Generic Error Msg Oh No! :-?",
          "detail" => reason
        }
      ]
    }
    {:error, error_msg}
  end

  # ------------------------------------------------------------------------
  # Helper
  # ------------------------------------------------------------------------

  @doc """
  Convenience wrapper that wraps validate call for use in `with` statement.
  _(Warning: Feels a little hacky.)_
  
  If using native `with`, then set `what` to just `name`.
  If using `OK.with`, then set `what` to `{:ok, name}`.
    
  (This is because I have existing code that uses native `with` and I don't 
  want to refactor it needlessly.)

  Examples:
  
  Native `with`:
    {:things, true} <- validate_input(:things, things, "Need things")
    Will return {:things, true} if valid, else {:error, emsg}
    
  `OK.with`:
    true <- validate_input({:ok, :things}, things, "Need things")
    Will return {:ok, true} if valid (which gets extracted), else {:error, emsg}
  """
  def validate_input(what, value, emsg)
  # This clause is for simple boolean expressions that don't call
  # outside validate function. I'm adding this so I can say src_ib_gib != root.
  def validate_input({:ok, name}, {:simple, valid?}, emsg) when is_boolean(valid?) do
    if valid? do
      {:ok, true}
    else
      {:error, emsg}
    end
  end
  def validate_input({:ok, name}, value, emsg) do
    {tag, result} = validate_input(name, value, emsg)
    if tag == :error do
      {:error, emsg}
    else
      {:ok, result}
    end
  end
  # This clause is for simple boolean expressions that don't call
  # outside validate function. I'm adding this so I can say src_ib_gib != root.
  def validate_input(name, {:simple, valid?}, emsg) when is_boolean(valid?) do
    if valid? do
      {name, true}
    else
      {:error, emsg}
    end
  end
  # This clause is for standard validation that calls outside validate function
  def validate_input(name, value, emsg) do
    if validate(name, value) do
      {name, true}
    else
      {:error, emsg}
    end
  end

  def validate_input(name, value, emsg, validate_type) do
    if validate(validate_type, value) do
      {name, true}
    else
      {:error, emsg}
    end
  end
end
