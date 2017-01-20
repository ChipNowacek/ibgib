defmodule WebGib.Plugs.EnsureIbGibUsername do
  @moduledoc """
  Ensures that there is an existing ib_gib session (not just a "proper" session
  which every request has). If none is found, then redirects to the home page
  for the user to read.
  """

  require Logger
  import Expat # https://github.com/vic/expat
  import Plug.Conn
  import Phoenix.Controller

  import WebGib.{Gettext, Patterns}
  use WebGib.Constants, :keys

  @doc """
  This options is created at "compile time" (when there is a request).
  It is then passed to the `call/2` function, so whatever is returned here
  will be used at runtime there.

  Returns `:ok` by default.
  """
  def init(options) do
    options
  end

  # Connection with a username
  defpat conn_ib_username_   conn_(ib_username_())

  defpat login_form_data_ %{"login_form_data" => ib_username_()}
  # Connection with a login form with the username
  defpat conn_login_form_data_ %Plug.Conn{
    body_params: (login_form_data_() = body_params)
  }
  
  @doc """
  The connection should either have a username stored in it or a login form
  with the username in _that_. If it doesn't, then redirect to the home page.
  """
  def call(conn, options)
  def call(conn_login_form_data_(...) = conn, options) do
    _ = Logger.debug("login_form_data username call. conn: #{inspect conn}" |> ExChalk.bg_cyan |> ExChalk.black)
    login_form_data = Map.get(body_params, "login_form_data")
    ib_username = login_form_data["ib_username"]
    if WebGib.Validate.validate(:ib, ib_username) do
      _ = Logger.debug("putting username in session: #{ib_username}" |> ExChalk.bg_cyan |> ExChalk.black)
      conn
      |> put_session(@ib_username_key, ib_username)
    else
      conn
      |> put_flash(:error, gettext("The username is invalid. Use just letters, numbers, underscores, dashes, and spaces.") <> " (#{ib_username})")
      |> redirect(to: "/ibgib/#{@root_ib_gib}")
      |> halt()
    end
  end
  def call(conn_(...) = conn, _options) do
    ib_username = conn |> get_session(@ib_username_key)
    if ib_username !== "" and WebGib.Validate.validate(:ib, ib_username) do
      _ = Logger.debug("conn contains valid ib_username. ib_username: #{ib_username}" |> ExChalk.bg_cyan |> ExChalk.black)
      conn
    else
      # No username and no form data that contains a username, so redirect home 
      # and halt
      _ = Logger.debug("current ib_username not supplied. redirecting home. conn: #{inspect conn}" |> ExChalk.bg_cyan |> ExChalk.black)
      conn
      |> put_flash(:info, gettext "After reading ibGib's Vision and Privacy Caution, please login with your username for the session. It does not need to be unique! You will then be redirected to your URL or taken to the Root. Thanks :-)")
      |> put_session(@path_before_redirect_key, conn.request_path)
      |> redirect(to: "/")
      |> halt
    end
  end
  
end
