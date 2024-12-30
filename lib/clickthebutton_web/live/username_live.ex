defmodule ClickthebuttonWeb.UsernameLive do
  use ClickthebuttonWeb, :live_view
  import Plug.Conn, only: [put_resp_cookie: 4]
  alias Clickthebutton.GameServer

  @topic "game:scores"

  @impl true
  def mount(_params, _session, socket) do
    # Check if user already has cookies set
    cookies = get_connect_params(socket)["cookies"] || %{}

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Clickthebutton.PubSub, @topic)
    end

    case cookies do
      %{"ctb_user_id" => _user_id, "ctb_username" => _username} ->
        {:ok, redirect(socket, to: ~p"/game")}

      _ ->
        {:ok,
         socket
         |> assign(:username, "")
         |> assign(:error, nil)
         |> assign(:leaderboard, GameServer.get_leaderboard())}
    end
  end

  @impl true
  def handle_info({:score_updated, _user_id, _new_score}, socket) do
    # Always refresh leaderboard when any score changes
    {:noreply, assign(socket, :leaderboard, GameServer.get_leaderboard())}
  end
end
