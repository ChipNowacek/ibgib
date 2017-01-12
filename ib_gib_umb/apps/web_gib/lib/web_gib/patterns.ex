defmodule WebGib.Patterns do
  @moduledoc """
  Reusable patterns using expat
  """
  
  import Expat # https://github.com/vic/expat
  
  defpat ib_gib_         %{"ib_gib" => ib_gib}
  defpat ib_gibs_        %{"ib_gibs" => ib_gibs}
  defpat dest_ib_        %{"dest_ib" => dest_ib}
  defpat src_ib_gib_     %{"src_ib_gib" => src_ib_gib}
  defpat context_ib_gib_ %{"context_ib_gib" => context_ib_gib}
  defpat adjunct_ib_gib_ %{"adjunct_ib_gib" => adjunct_ib_gib}
  defpat comment_text_   %{"comment_text" => comment_text}
  defpat link_text_      %{"link_text" => link_text}
  
  defpat ib_identity_ib_gibs_ %{ib_identity_ib_gibs: identity_ib_gibs}
  defpat assigns_identity_ib_gibs_ %{assigns: ib_identity_ib_gibs_()}
end
