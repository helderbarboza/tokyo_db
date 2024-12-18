defmodule TokyoDB.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger
  alias TokyoDB.Database

  @impl true
  def start(_type, _args) do
    children =
      [
        TokyoDBWeb.Telemetry,
        {DNSCluster, query: Application.get_env(:tokyo_db, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: TokyoDB.PubSub},
        # Start a worker by calling: TokyoDB.Worker.start_link(arg)
        # {TokyoDB.Worker, arg},
        # Start to serve requests, typically the last entry
        TokyoDBWeb.Endpoint
      ] ++ Enum.map(tables(), &{&1, []})

    setup_store()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TokyoDB.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TokyoDBWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp tables do
    [Database.KV, Database.TransactionLog]
  end

  defp setup_store do
    Logger.debug("Setting up store...")

    :ok = ensure_schema_exists()
    :ok = :mnesia.start()

    for module <- tables() do
      :ok = module.create_table()
      :ok = :mnesia.wait_for_tables([module], 5000)
    end

    Logger.debug("...Store set up!")
  end

  defp ensure_schema_exists do
    case :mnesia.create_schema([node()]) do
      {:error, {_node, {:already_exists, __node}}} -> :ok
      :ok -> :ok
    end
  end
end
