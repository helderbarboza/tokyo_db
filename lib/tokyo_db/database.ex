defmodule TokyoDB.Database do
  @moduledoc """
  Database and schema management.
  """

  require Logger
  alias :mnesia, as: Mnesia

  alias __MODULE__

  @doc "Lists tables available."
  def tables do
    [Database.KV, Database.TransactionLog]
  end

  @doc "Starts Mnesia and checks if schema and tables are ready."
  def setup_store do
    Logger.debug("Setting up store...")

    :ok = ensure_schema_exists()
    :ok = Mnesia.start()

    for module <- tables() do
      :ok = module.create_table()
      :ok = Mnesia.wait_for_tables([module], 5000)
    end

    Logger.debug("...Store set up!")
  end

  defp ensure_schema_exists do
    case Mnesia.create_schema([node()]) do
      {:error, {_node, {:already_exists, __node}}} -> :ok
      :ok -> :ok
    end
  end
end
