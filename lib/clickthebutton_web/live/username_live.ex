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

  @impl true
  def handle_event("save", %{"username" => username}, socket) do
    case validate_username(username) do
      :ok ->
        user_id = "user_" <> UUID.uuid4(:hex)

        # Set cookies with 1 year expiry
        socket =
          socket
          |> put_resp_cookie("ctb_user_id", user_id, max_age: 31_536_000, path: "/")
          |> put_resp_cookie("ctb_username", username, max_age: 31_536_000, path: "/")

        {:noreply, redirect(socket, to: ~p"/game")}

      {:error, message} ->
        {:noreply, assign(socket, :error, message)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen items-center justify-center bg-gray-50">
      <div class="w-full max-w-md">
        <div class="rounded-lg bg-white p-8 shadow-md">
          <h2 class="mb-6 text-2xl font-bold text-center text-gray-900">Enter Your Username</h2>

          <.form for={%{}} action={~p"/username"} method="post" class="space-y-4">
            <div>
              <.input
                type="text"
                name="username"
                value={@username}
                placeholder="Choose a username"
                required
                class="w-full"
              />

              <%= if @error do %>
                <p class="mt-1 text-sm text-red-600">{@error}</p>
              <% end %>
            </div>

            <button
              type="submit"
              class="w-full rounded-md bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
            >
              Start Playing
            </button>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  defp validate_username(username) do
    cond do
      String.length(username) < 3 ->
        {:error, "Username must be at least 3 characters"}

      String.length(username) > 16 ->
        {:error, "Username must be less than 16 characters"}

      not String.match?(username, ~r/^[a-zA-Z0-9_]+$/) ->
        {:error, "Username can only contain letters, numbers, and underscores"}

      true ->
        :ok
    end
  end
end
