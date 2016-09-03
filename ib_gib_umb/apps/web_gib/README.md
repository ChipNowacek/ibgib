# WebGib

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix









##  To connect to phoenix server with observer
[Thanks gaslight!](https://teamgaslight.com/blog/microservices-in-phoenix-part-1)

`iex -S mix phoenix.server`


## This is what a form output looks like. I'm using this for use with
[Marker](https://github.com/zambal/marker).

<form accept-charset="UTF-8" action="/ibgib/api/fork" class="ib-circular-menuable" method="post">
  <input name="_csrf_token" type="hidden" value="dCYHb0MuNn9gHzhcJ3xGEyoVHRstAAAACwU9wDyP8hn3cNpbXLkwEg==">
  <input name="_utf8" type="hidden" value="✓">        
  <input id="fork_form_data_dest_ib" name="fork_form_data[dest_ib]" type="text">
  <input id="fork_form_data_src_ib_gib" name="fork_form_data[src_ib_gib]" type="hidden" value="RNimgKOAtJiOHbLfzWivVKvjirKSfD^C53A82228C71A9D5B0EE75C889878884634D841F925A2AB3609D8FF4AB5899B5">        
  <div class="ib-tooltip">
    <button type="submit">
      <span class="ib-center-glyph glyphicon glyphicon-flash ib-green"></span>
      <span class="ib-tooltiptext">Fork it yo!</span>
    </button>
    <!-- <input type="submit" value="⎇"> -->
  </div>
</form>


## Notes from channel

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.
