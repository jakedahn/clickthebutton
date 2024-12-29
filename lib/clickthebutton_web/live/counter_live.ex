defmodule ClickthebuttonWeb.CounterLive do
  use ClickthebuttonWeb, :live_view
  alias Clickthebutton.GameServer
  require IEx

  @topic "game:scores"

  @impl true
  def mount(_params, session, socket) do
    case {session["user_id"], session["username"]} do
      {user_id, username} when is_binary(user_id) and is_binary(username) ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(Clickthebutton.PubSub, @topic)
        end

        {:ok,
         socket
         |> assign(:user_id, user_id)
         |> assign(:username, username)
         |> assign(:count, GameServer.get_score(user_id))
         |> assign(:throttled_until, nil)
         |> assign(:leaderboard, GameServer.get_leaderboard())}

      _ ->
        {:ok, redirect(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_event("increment", _params, socket) do
    case GameServer.increment_score(socket.assigns.user_id, %{username: socket.assigns.username}) do
      {:ok, new_score} ->
        {:noreply, assign(socket, :count, new_score)}

      {:throttled, until} ->
        {:noreply, assign(socket, :throttled_until, until)}
    end
  end

  @impl true
  def handle_info({:score_updated, _user_id, _new_score}, socket) do
    # Always refresh leaderboard when any score changes
    {:noreply, assign(socket, :leaderboard, GameServer.get_leaderboard())}
  end

  @impl true
  def handle_info({:user_throttled, user_id, until}, socket)
      when user_id == socket.assigns.user_id do
    {:noreply, assign(socket, :throttled_until, until)}
  end

  def handle_info({:user_throttled, _user_id, _until}, socket) do
    {:noreply, socket}
  end
end
