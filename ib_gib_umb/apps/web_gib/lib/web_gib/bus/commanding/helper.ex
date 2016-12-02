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
  # Example:
  # If valid, will return e.g. {:dest_ib, true}
  # Invalid, will return e.g. {:error, emsg}
  # Not thrilled, but it's very slow going right now :-/ (should refactor)
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
