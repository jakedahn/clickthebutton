defmodule ClickthebuttonWeb.EnsureUsernamePlug do
  import Phoenix.Controller
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, "ctb_username") do
      nil ->
        conn
        |> redirect(to: "/")
        |> halt()

      _username ->
        conn
    end
  end
end
