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

  import OK, only: ["~>>": 2]
  require Logger
  require OK

  alias IbGib.Auth.Authz
  import IbGib.{Expression, Helper, Macros}
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

  @doc """
  Creates an oy of a given `oy_kind` with the given `details`
  """
  def create_and_publish_oy(oy_kind, oy_details)
  def create_and_publish_oy(oy_kind = :adjunct, 
                            oy_details = %{
                              "name" => oy_name,
                              "adjunct" => adjunct,
                              "adjunct_identities" => adjunct_identities,
                              "target" => target,
                              "target_email_identities" => target_email_identities
                            }) 
    when is_list(target_email_identities) and length(target_email_identities) > 0 do
    # This is a notification that someone with adjunct_identities has created
    # an adjunct with the target_ib_gib
    OK.with do
      _ = Logger.debug("creating oy. oy_kind: #{oy_kind}")
      oy_gib <- IbGib.Expression.Supervisor.start_expression("oy#{@delim}gib")
      oy <- 
        oy_gib
        |> instance_oy(adjunct_identities, oy_kind, oy_name)  
        ~>> rel8(adjunct, adjunct_identities, ["adjunct"])
        ~>> rel8(target, adjunct_identities, ["target"])
        ~>> rel8_oy_to_all_target_email_identities(target_email_identities, adjunct_identities)
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end
  def create_and_publish_oy(oy_kind, oy_details) do
    invalid_args([oy_kind, oy_details])
  end
  
  defp instance_oy(oy_gib, identity_ib_gibs, oy_kind, oy_name) do
    oy_gib 
    |> instance(identity_ib_gibs, "oy #{oy_kind} #{oy_name}")
  end
  
  # We need to rel8 the oy to each and every email identity
  defp rel8_oy_to_all_target_email_identities(oy, 
                                              target_email_identities,
                                              adjunct_identities) do
    target_email_identities
    |> Enum.reduce_while({:ok, oy}, fn(email_identity_ib_gib, {:ok, acc_oy}) -> 
        case rel8_to_email(acc_oy, email_identity_ib_gib, adjunct_identities) do
          {:ok, new_oy} -> {:cont, {:ok, new_oy}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
  end
  
  # Individual iteration of above rel8 to all func
  defp rel8_to_email(oy, email_identity_ib_gib, adjunct_identities) 
    when email_identity_ib_gib != nil do
    OK.with do
      email_identity <-
        IbGib.Expression.Supervisor.start_expression(email_identity_ib_gib) 
      
      new_oy <- 
        oy |> rel8(email_identity, adjunct_identities, ["target_identity"])
      
      OK.success new_oy
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end
  defp rel8_to_email(oy, email_identity_ib_gib, adjunct_identities) do
    invalid_args([oy, email_identity_ib_gib, adjunct_identities])
  end
end
