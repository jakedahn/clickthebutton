defmodule Clickthebutton.Repo do
  use Ecto.Repo,
    otp_app: :clickthebutton,
    adapter: Ecto.Adapters.Postgres
end
