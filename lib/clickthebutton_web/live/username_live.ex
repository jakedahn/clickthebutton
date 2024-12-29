defmodule ClickthebuttonWeb.UsernameLive do
  use ClickthebuttonWeb, :live_view
  import Plug.Conn, only: [put_resp_cookie: 4]

  @impl true
  def mount(_params, _session, socket) do
    # Check if user already has cookies set
    cookies = get_connect_params(socket)["cookies"] || %{}

    case cookies do
      %{"ctb_user_id" => _user_id, "ctb_username" => _username} ->
        {:ok, redirect(socket, to: ~p"/game")}

      _ ->
        {:ok,
         socket
         |> assign(:username, "")
         |> assign(:error, nil)}
    end
  end
end
