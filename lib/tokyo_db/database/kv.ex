defmodule TokyoDB.Database.KV do
  @moduledoc "A `:mnesia` store for key-value data"

  use GenServer
  require Logger

  defstruct [:key, :value]

  @impl true
  def init(state) do
    setup_store()

    {:ok, state}
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  defp setup_store do
    Logger.debug("Setting up store...")

    :ok = ensure_schema_exists()
    :ok = :mnesia.start()
    :ok = ensure_table_exists()

    Logger.debug("...Store set up!")
  end

  defp ensure_schema_exists do
    case :mnesia.create_schema([node()]) do
      {:error, {_node, {:already_exists, __node}}} -> :ok
      :ok -> :ok
    end
  end

  defp ensure_table_exists do
    case :mnesia.create_table(__MODULE__, attributes: [:key, :value]) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, __MODULE__}} -> :ok
    end

    :ok = :mnesia.wait_for_tables([__MODULE__], 5000)
  end
end
