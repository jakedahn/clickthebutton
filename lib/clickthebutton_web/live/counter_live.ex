defmodule ClickthebuttonWeb.CounterLive do
  use ClickthebuttonWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  @impl true
  def handle_event("increment", _params, socket) do
    {:noreply,
     socket
     |> assign(:count, socket.assigns.count + 1)}
  end
end
