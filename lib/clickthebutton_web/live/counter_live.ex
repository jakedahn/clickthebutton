defmodule ClickthebuttonWeb.CounterLive do
  use ClickthebuttonWeb, :live_view
  alias Clickthebutton.GameServer

  @topic "game:scores"

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Clickthebutton.PubSub, @topic)
    end

    user_id = session["ctb_user_id"]

    {:ok,
     socket
     |> assign(:user_id, user_id)
     |> assign(:count, GameServer.get_score(user_id))
     |> assign(:leaderboard, GameServer.get_leaderboard())}
  end

  @impl true
  def handle_event("increment", _params, socket) do
    new_score = GameServer.increment_score(socket.assigns.user_id)

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
