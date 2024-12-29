defmodule ClickthebuttonWeb.UserSessionPlug do
  import Plug.Conn

  def init(_), do: %{}

  def call(conn, _opts) do
    conn = fetch_cookies(conn)
    user_id = conn.cookies["ctb_user_id"]
    username = conn.cookies["ctb_username"]

    conn
    |> put_session(:user_id, user_id)
    |> put_session(:username, username)
    |> assign(:user_id, user_id)
    |> assign(:username, username)
  end
end
