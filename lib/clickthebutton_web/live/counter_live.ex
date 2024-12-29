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
         |> assign(:leaderboard, GameServer.get_leaderboard())}

      _ ->
        {:ok, redirect(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_event("increment", _params, socket) do
    new_score =
      GameServer.increment_score(socket.assigns.user_id, %{username: socket.assigns.username})

    {:noreply,
     socket
     |> assign(:count, new_score)}
  end

  # Handle the score_updated message from PubSub
  @impl true
  def handle_info({:score_updated, user_id, new_score}, socket) do
    {:noreply,
     socket
     |> maybe_update_count(user_id, new_score)
     |> assign(:leaderboard, GameServer.get_leaderboard())}
  end

  # Helper function to update count only if it's the current user
  defp maybe_update_count(socket, user_id, new_score) when user_id == socket.assigns.user_id do
    assign(socket, :count, new_score)
  end

  defp maybe_update_count(socket, _user_id, _new_score), do: socket
end
