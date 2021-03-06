defmodule WebGib.IbGibSocket do
  require Logger
  use Phoenix.Socket

  use WebGib.Constants, :config

  ## Channels
  # This is where we match a server-side Channel module to the route.
  channel "command:*", WebGib.Bus.Channels.Command
  channel "event:*", WebGib.Bus.Channels.Event

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket,
    timeout: 1_800_000
  transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"token" => token} = _params, socket) do
    _ = Logger.debug("connecting with token: #{token}" |> ExChalk.yellow |> ExChalk.bg_blue)
    case Phoenix.Token.verify(WebGib.Endpoint, @ib_identity_token_salt, token, max_age: @ib_identity_token_max_age) do
      {:ok, identity_ib_gibs} ->
        _ = Logger.debug("verified token identity_ib_gibs: #{inspect identity_ib_gibs}" |> ExChalk.yellow |> ExChalk.bg_blue)
        {:ok, assign(socket, :ib_identity_ib_gibs, identity_ib_gibs)}

      {:error, :expired} ->
        emsg = "Session expired. Please log back in."
        _ = Logger.error(emsg)
        {:error, %{reason: emsg}}

      {:error, reason} ->
        emsg = "Unauthorized. Session invalid. Please log in first."
        _ = Logger.error("#{emsg}\nReason: #{inspect reason}")
        {:error, %{reason: emsg}}
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     WebGib.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil

end
