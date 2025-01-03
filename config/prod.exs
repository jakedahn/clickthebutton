import Config

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix assets.deploy` task,
# which you should run after static files are built and
# before starting your production server.
config :clickthebutton, ClickthebuttonWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  http: [port: {:system, "PORT"}],
  url: [scheme: "https", host: "clickthebutton.lol", port: 443],
  check_origin: ["https://clickthebutton.lol", "https://clickthebutton.fly.dev"],
  game_state_path: "/app/data/game_state.dat"

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Clickthebutton.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
