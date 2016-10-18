defmodule WebGib.MarkerElements do
  @moduledoc """
  Provides custom elements
  """
  use Marker.Element, tags: [
    :svg,
    :circle,
    :line,
    :text,
    :strong
  ]
end
