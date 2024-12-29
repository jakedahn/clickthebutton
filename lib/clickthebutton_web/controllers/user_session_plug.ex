defmodule ClickthebuttonWeb.UserSessionPlug do
  import Plug.Conn

  @cookie_name "ctb_user"
  # 365 days
  @cookie_max_age 60 * 60 * 24 * 365

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, @cookie_name) do
      nil ->
        # Generate new user ID if none exists
        user_id = "user_" <> generate_uuid()

        conn
        |> put_session(@cookie_name, user_id)
        |> put_resp_cookie(@cookie_name, user_id, max_age: @cookie_max_age)

      user_id ->
        # Refresh the cookie if it exists
        put_resp_cookie(conn, @cookie_name, user_id, max_age: @cookie_max_age)
    end
  end

  defp generate_uuid do
    UUID.uuid4(:hex)
  end
end
