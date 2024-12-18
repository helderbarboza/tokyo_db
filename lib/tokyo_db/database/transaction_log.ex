defmodule TokyoDB.Database.TransactionLog do
  @moduledoc """
  Stores the transactions created by the clients.
  """

  use GenServer
  alias TokyoDB.Database.Operation
  alias :mnesia, as: Mnesia

  @table __MODULE__

  defstruct [:client_name, :operations]

  @type t :: %__MODULE__{client_name: String.t(), operations: [Operation.t()]}

  @impl true
  def init(state) do
    {:ok, state}
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @doc false
  def create_table do
    case Mnesia.create_table(@table,
           attributes: [:client_name, :operations],
           disc_only_copies: [node()]
         ) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, @table}} -> :ok
    end
  end
end
