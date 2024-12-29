defmodule ClickthebuttonWeb.UsernameController do
  use ClickthebuttonWeb, :controller

  def create(conn, %{"username" => username}) do
    case validate_username(username) do
      :ok ->
        user_id = "user_" <> UUID.uuid4(:hex)

        conn
        |> put_resp_cookie("ctb_user_id", user_id, max_age: 31_536_000, path: "/")
        |> put_resp_cookie("ctb_username", username, max_age: 31_536_000, path: "/")
        |> redirect(to: ~p"/game")

      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: ~p"/")
    end
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
