defmodule WebGib.Oy do
  @moduledoc """
  Functions related to oy notifications.

  An oy^gib is a prioritized event ibGib (not just an ephemeral event published
  to the event bus). First, I'm going to just create this module that contains
  function(s) related to creating an oy^gib. Then this will be callable from
  within WebGib commands, e.g. WebGib.Bus.Commanding.Comment, as well as from
  other autonomous services (smart microservices). 
  
  ## Side Note - IbGib vs. WebGib placement
  
  I'm still not sure about how I should structure some of the things, such as
  this module. Where should I put it? Does it go in IbGib app (where the 
  engine is), or is this a WebGib thing only? Or is there another layer I should
  create that contains this kind of logic? It definitely seems like shareable
  code, but I don't want to put it in the engine proper.
  """

  require Logger
  require OK

  alias IbGib.Auth.Authz
  import IbGib.{Expression, Helper, Macros}
  use IbGib.Constants, :ib_gib

  @doc """
  Creates an oy of a given `oy_kind` with the given `details`
  """
  def create_and_publish_oy(oy_kind, oy_details)
  def create_and_publish_oy(_oy_kind = :adjunct, 
                            _oy_details = %{
                              "adjunct_identities" => adjunct_identities,
                              "adjunct_ib_gib" => adjunct_ib_gib,
                              "target_identities" => target_identities,
                              "target_ib_gib" => target_ib_gib
                            }) do
    # This is a notification that someone with adjunct_identities has created
    # an adjunct with adjunct_ib_gib to the target_ib_gib, with 
    # target_identities given for convenience.
    
  end
  def create_and_publish_oy(oy_kind, oy_details) do
    invalid_args([oy_kind, oy_details])
  end
end
