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
    {:reply, {:error, error_msg}, socket}
  end

  # ------------------------------------------------------------------------
  # Helper
  # ------------------------------------------------------------------------

  # Convenience wrapper that wraps validate call for use in `with` statement
  # error pattern matching.
  # Not thrilled, but it's very slow going right now :-/ (should refactor)
  # Example:
  # If valid, will return e.g. {:dest_ib, true}
  # Invalid,  will return e.g. {:error, emsg}
  def validate_input(name, value, emsg)
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
