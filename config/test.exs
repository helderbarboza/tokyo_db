import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :tokyo_db, TokyoDBWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "GrC1SEkN87M9863TgRLO79opZgv8Mme2clK4CBg4MhWl0CGXYoA8R23uoBUkTqFP",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
