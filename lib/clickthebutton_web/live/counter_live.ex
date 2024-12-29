defmodule ClickthebuttonWeb.CounterLive do
  use ClickthebuttonWeb, :live_view
  alias Clickthebutton.GameServer

  @topic "game:scores"

  @impl true
  def mount(_params, _session, socket) do
    # Check cookies for user data
    cookies = get_connect_params(socket)["cookies"] || %{}

    case cookies do
      %{"ctb_user_id" => user_id, "ctb_username" => username} ->
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
