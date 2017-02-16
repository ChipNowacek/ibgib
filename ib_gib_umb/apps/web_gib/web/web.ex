defmodule WebGib.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use WebGib.Web, :controller
      use WebGib.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def controller do
    quote do
      require Logger
      use Phoenix.Controller

      import IbGib.{Helper, Macros}
      import WebGib.{Gettext, Router.Helpers}
      use IbGib.Constants, :error_msgs
      use IbGib.Constants, :ib_gib
      use WebGib.Constants, :error_msgs
      use WebGib.Constants, :keys
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      # use Phoenix.HTML
      use Marker
      use WebGib.MarkerElements

      import WebGib.{ErrorHelpers, Gettext, Router.Helpers}
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
