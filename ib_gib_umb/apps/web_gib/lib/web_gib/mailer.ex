defmodule WebGib.Mailer do
  @moduledoc """
  Contains the implementation for sending a mail.
  ATOW, uses mailgun.
  """

  alias WebGib.{Endpoint, Router}
  use Mailgun.Client,
      domain: Application.get_env(:web_gib, :mailgun_domain),
      key: Application.get_env(:web_gib, :mailgun_key)


  def send_login_token(email_addr, token) do
    send_email to: email_addr,
    from: login_email_from,
    subject: login_email_subject,
    text: login_email_body(token)
  end

  defp token_url(token) do
    Router.Helpers.ib_gib_url(Endpoint, :ident, token)
  end

  def login_email_from, do: "noreply-login@ibgib.com"

  def login_email_subject, do: "ibGib Login Identity Link"

  def login_email_body(token) do
    ~s"""
    Howdy!

    Use the following link to login this email as a current identity.

    (Be sure to open the link in the **same** browser that you used to generate it.)

    #{token_url(token)}

    Thanks :-O

    ibGib
    """
  end
end
