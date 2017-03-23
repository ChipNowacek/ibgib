defmodule WebGib.Oy do
  @moduledoc """
  Functions related to durable events in ibGib called oys. (Oy!)

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

  alias IbGib.Auth.Authz
  alias IbGib.Common
  alias WebGib.Bus.Channels.Event, as: EventChannel
  import IbGib.{Expression, Helper, Macros, QueryOptionsFactory}
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :error_msgs

# -----------------------------------------------------------
# create_and_publish_oy
# -----------------------------------------------------------

  @doc """
  Creates an oy of a given `oy_kind` with the given `details`
  
  ## oy_kind
  
  ### :adjunct
  
  This is a notification that someone with adjunct_identities has created
  an adjunct with the target_ib_gib.
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
    _ = Logger.debug("creating oy. oy_kind: #{oy_kind}\noy_details: #{inspect oy_details}")
    OK.with do
      oy <- 
        {:ok, "oy#{@delim}gib"}
        ~>> IbGib.Expression.Supervisor.start_expression()
        ~>> instance_oy(adjunct_identities, oy_kind, oy_name)  
        ~>> rel8(adjunct, adjunct_identities, ["adjunct"])
        ~>> rel8(target, adjunct_identities, ["target"])
        ~>> rel8_oy_to_all_target_email_identities(target_email_identities, adjunct_identities)
      
      oy_ib_gib <-
        {:ok, oy}
        ~>> get_info()
        ~>> get_ib_gib()
      
      :ok <- 
        EventChannel.broadcast_ib_gib_event(:oy, 
                                            {oy_kind, 
                                             oy_name, 
                                             oy_ib_gib, 
                                             adjunct_identities,
                                             target_email_identities})
      
      OK.success :ok
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
        case rel8_to_email(acc_oy, 
                           email_identity_ib_gib, 
                           adjunct_identities) do
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

# -----------------------------------------------------------
# is_new?
# -----------------------------------------------------------

  def is_new?(oy_ib_gib, oy_kind \\ nil)
  def is_new?(oy_ib_gib, nil) do
    _ = Logger.debug("oy_ib_gib: #{oy_ib_gib}.\noy_kind: nil")
    OK.with do
      oy_kind <- get_oy_kind(oy_ib_gib)
      is_new?(oy_ib_gib, oy_kind)
    end
  end
  def is_new?(oy_ib_gib, oy_kind = "adjunct") do
    _ = Logger.debug("oy_ib_gib: #{oy_ib_gib}.\noy_kind: #{oy_kind}")
    OK.with do
      oy_info <- 
        {:ok, oy_ib_gib}
        ~>> IbGib.Expression.Supervisor.start_expression()
        ~>> get_info()
        
      [oy_adjunct_ib_gib] <- get_rel8ns(oy_info, "adjunct")
      _ = Logger.debug("iznn oy_adjunct_ib_gib: #{oy_adjunct_ib_gib}")

      [oy_target_ib_gib] <- get_rel8ns(oy_info, "target")
      _ = Logger.debug("iznn oy_target_ib_gib: #{oy_target_ib_gib}")
      
      oy_adjunct_info <- 
        {:ok, oy_adjunct_ib_gib}
        ~>> IbGib.Expression.Supervisor.start_expression()
        ~>> get_info()
      oy_target_info <- 
        {:ok, oy_target_ib_gib}
        ~>> IbGib.Expression.Supervisor.start_expression()
        ~>> get_info()

      # We need to get the latest target info to compare rel8nships.
      oy_target_identities <- get_rel8ns(oy_target_info, "identity")
      latest_oy_target_info <- 
        {:ok, oy_target_identities}
        ~>> Common.get_latest_ib_gib(oy_target_ib_gib)
        ~>> IbGib.Expression.Supervisor.start_expression()
        ~>> get_info()

      direct_rel8nships <- 
        get_direct_rel8nships(:a_now_b_anytime,
                              latest_oy_target_info,
                              oy_adjunct_info)

      
      _ = Logger.debug("iznn direct_rel8nships: #{inspect direct_rel8nships}")
      is_new? = map_size(direct_rel8nships) === 0
      
      _ = Logger.debug "iznn is_new?: #{is_new?}"
      OK.success is_new?
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end 
  end

# -----------------------------------------------------------
# get_oy_kind
# -----------------------------------------------------------
    
  @doc """
  Determines the oy_kind from the given argument. It can be either 
  an ib_gib, an info, or the oy pid (reference) itself.
  
  Example of the ib_gib overload:
    iex> Logger.disable(self())
    ...> result = WebGib.Oy.get_oy_kind("oy adjunct pic^ABC123")
    ...> Logger.enable(self())
    ...> result
    {:ok, "adjunct"}
  """
  def get_oy_kind(oy_ib_gib_or_info_or_pid)
  def get_oy_kind(oy_ib_gib) when is_bitstring(oy_ib_gib) do
    OK.with do
      {ib, _gib} <- separate_ib_gib(oy_ib_gib)
      [_, oy_kind, _] = String.split(ib, " ")
      OK.success oy_kind
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end
  def get_oy_kind(oy_info) when is_map(oy_info) do
    ib = oy_info[:ib]
    [_, oy_kind, _] = String.split(ib, " ")
    {:ok, oy_kind}
  end
  def get_oy_kind(oy_pid) when is_pid(oy_pid) do
    OK.with do
      oy_info <- oy_pid |> get_info()
      get_oy_kind(oy_info)
    else
      reason -> OK.failure handle_ok_error(reason, log: true)
    end
  end
  def get_oy_kind(oy_ib_gib_or_info_or_pid) do
    invalid_args(oy_ib_gib_or_info_or_pid)
  end

# -----------------------------------------------------------
# other helpers that I could very well need later. meh. 
# keeping it around. (took out the other stuff not needed)
# -----------------------------------------------------------

  # defp find_oy(identity_ib_gibs, adjunct_ib_gib) do
  #   OK.with do
  #     {email_identity_ib_gibs, query_identity} <-
  #       prepare(identity_ib_gibs)
  #       
  #     query_opts <- 
  #       build_find_oy_query_opts(:adjunct, 
  #                                %{"email_identity_ib_gibs" =>
  #                                    email_identity_ib_gibs, 
  #                                  "adjunct_ib_gib" => 
  #                                    adjunct_ib_gib})
  # 
  #     oy <- 
  #       {:ok, query_identity} 
  #       ~>> query(identity_ib_gibs, query_opts)
  #       ~>> get_info()
  #       ~>> extract_result_ib_gibs([prune_root: true])
  #       ~>> Common.filter_present_only(identity_ib_gibs)
  #       ~>> extract_single_oy_ib_gib()
  #       ~>> IbGib.Expression.Supervisor.start_expression()
  # 
  #     OK.success oy
  #   else
  #     reason -> OK.failure handle_ok_error(reason, log: true)
  #   end
  # end
  # 
  # # Prepare is just corralling data without much logic.
  # defp prepare(identity_ib_gibs) do
  #   OK.with do
  #     # email identities are used for the query contents
  #     email_identity_ib_gibs <- 
  #       Authz.get_identities_of_type(identity_ib_gibs, "email")
  #     :ok <- 
  #       if length(email_identity_ib_gibs) > 0, do: {:ok, :ok}, else: {:error, :no_email_id}
  # 
  #     # identity ib^gib & process used to exec the query
  #     query_identity_ib_gib = email_identity_ib_gibs |> Enum.at(0)
  #     query_identity <- 
  #       IbGib.Expression.Supervisor.start_expression(query_identity_ib_gib)
  # 
  #     # # adjunct to query for
  #     # adjunct_ib_gib <-
  #     #   {:ok, adjunct}
  #     #   ~>> get_info() 
  #     #   ~>> get_ib_gib()
  # 
  #     OK.success {email_identity_ib_gibs, query_identity}
  #   else
  #     :no_email_id -> 
  #       emsg = "Current identity has no email identities, and so no oys."
  #       OK.failure handle_ok_error(emsg, log: true)
  #     reason -> 
  #       OK.failure handle_ok_error(reason, log: true)
  #   end
  # end
  # 
  # 
  # defp extract_single_oy_ib_gib(oy_ib_gibs) 
  #   when is_list(oy_ib_gibs) and length(oy_ib_gibs) == 0 do
  #   {:error, :oy_not_found}
  # end
  # defp extract_single_oy_ib_gib(oy_ib_gibs) 
  #   when is_list(oy_ib_gibs) and length(oy_ib_gibs) == 1 do
  #   oy_ib_gib = Enum.at(oy_ib_gibs, 0)
  #   if oy_ib_gib === @root_ib_gib do
  #     {:error, :oy_not_found}
  #   else
  #     {:ok, oy_ib_gib}
  #   end
  # end
  # defp extract_single_oy_ib_gib(oy_ib_gibs) 
  #   when is_list(oy_ib_gibs) and length(oy_ib_gibs) > 1 do
  #   oy_ib_gibs = oy_ib_gibs -- [@root_ib_gib]
  #   cond do
  #     length(oy_ib_gibs) == 1 ->
  #       {:ok, Enum.at(oy_ib_gibs, 0)}
  #       
  #     length(oy_ib_gibs) > 1 ->
  #       Logger.info("Multiple oys found in oy_ib_gibs. oy_ib_gibs: #{inspect oy_ib_gibs}")
  #       {:ok, Enum.at(oy_ib_gibs, 0)}
  #       
  #     true ->
  #       Logger.error "oy_ib_gibs length is 0? I dunno. oy_ib_gibs: #{inspect oy_ib_gibs}"
  #       {:error, :oy_not_found}
  #   end
  # end
  # 
  # defp build_find_oy_query_opts(oy_kind = :adjunct, 
  #                               find_details = %{
  #                                 "email_identity_ib_gibs" => email_identity_ib_gibs,
  #                                 "adjunct_ib_gib" => adjunct_ib_gib
  #                               }) do
  #   _ = Logger.debug("oy_kind: #{oy_kind}\nfind_details: #{inspect find_details}" |> ExChalk.bg_green |> ExChalk.white)
  #   query_opts = 
  #     do_query()
  #     |> where_rel8ns("ancestor", "with", "ibgib", "oy#{@delim}gib")
  #     |> where_rel8ns("adjunct", "with", "ibgib", adjunct_ib_gib)
  #     |> where_rel8ns("target_identity", "withany", "ibgib",
  #                     email_identity_ib_gibs)
  #   {:ok, query_opts}
  # end
  # defp build_find_oy_query_opts(oy_kind, find_details) do
  #   invalid_args([oy_kind, find_details])
  # end

end
