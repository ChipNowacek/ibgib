defmodule WebGib.Patterns do
  @moduledoc """
  Reusable patterns using expat
  """
  
  import Expat # https://github.com/vic/expat
  
  use WebGib.Constants, :keys
  
  defpat ib_gib_         %{"ib_gib" => ib_gib}
  defpat ib_gibs_        %{"ib_gibs" => ib_gibs}
  defpat dest_ib_        %{"dest_ib" => dest_ib}
  defpat src_ib_gib_     %{"src_ib_gib" => src_ib_gib}
  defpat context_ib_gib_ %{"context_ib_gib" => context_ib_gib}
  defpat adjunct_ib_gib_ %{"adjunct_ib_gib" => adjunct_ib_gib}
  defpat comment_text_   %{"comment_text" => comment_text}
  defpat link_text_      %{"link_text" => link_text}
  defpat ib_username_    %{@ib_username_key => ib_username}
  
  defpat params_         %{params: params}
  defpat conn_           %Plug.Conn{params: params}
  
  defpat ib_identity_ib_gibs_ %{ib_identity_ib_gibs: identity_ib_gibs}
  defpat assigns_identity_ib_gibs_ %{assigns: ib_identity_ib_gibs_()}
  
  # Connection with a username
  defpat conn_ib_username_   conn_(ib_username_())
  defpat login_form_data_ %{"login_form_data" => ib_username_()}
  # Connection with a login form with the username
  defpat conn_login_form_data_ %Plug.Conn{
    body_params: (login_form_data_() = body_params)
  }

end
