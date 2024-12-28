defmodule Clickthebutton.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ClickthebuttonWeb.Telemetry,
      Clickthebutton.Repo,
      {DNSCluster, query: Application.get_env(:clickthebutton, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Clickthebutton.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Clickthebutton.Finch},
      # Start a worker by calling: Clickthebutton.Worker.start_link(arg)
      # {Clickthebutton.Worker, arg},
      # Start to serve requests, typically the last entry
      ClickthebuttonWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Clickthebutton.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ClickthebuttonWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
