# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :tokyo_db,
  namespace: TokyoDB,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :tokyo_db, TokyoDBWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: TokyoDBWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TokyoDB.PubSub,
  live_view: [signing_salt: "ngB/KjG4"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

(
  base_path = ["~", "/.tokyo_db", "/#{to_string(Mix.env())}"]
  mnesia_dir_path = Path.expand(base_path ++ ["/mnesia"])
  mnesia_snapshots_dir_path = Path.expand(base_path ++ ["/mnesia-snapshots"])
  File.exists?(mnesia_dir_path) || File.mkdir_p!(mnesia_dir_path)

  config :mnesia, :dir, to_charlist(mnesia_dir_path)
  config :tokyo_db, snapshot_dir: mnesia_snapshots_dir_path
)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
