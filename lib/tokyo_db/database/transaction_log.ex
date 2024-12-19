defmodule TokyoDB.Database.TransactionLog do
  @moduledoc """
  Stores the transactions created by the clients.
  """

  use GenServer
  alias TokyoDB.Database.TransactionLog.Operation
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

  @spec insert(any()) :: :ok | {:error, atom()}
  def insert(client_name) do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        case Mnesia.match_object({@table, client_name, :_}) do
          [] -> Mnesia.write({@table, client_name, []})
          [_] -> {:error, :transaction_exists}
        end
      end)

    result
  end

  @spec get(any()) :: t() | nil
  def get(client_name) do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        case Mnesia.match_object({@table, client_name, :_}) do
          [transaction] -> decode(transaction)
          [] -> nil
        end
      end)

    result
  end

  @spec get!(any()) :: t()
  def get!(client_name) do
    get(client_name) || raise RuntimeError, message: "no transactions found"
  end

  @spec delete(any()) :: :ok | {:error, atom()}
  def delete(client_name) do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        case Mnesia.match_object({@table, client_name, :_}) do
          [transaction] -> :ok = Mnesia.delete_object(transaction)
          [] -> {:error, :transaction_not_found}
        end
      end)

    result
  end

  @spec put_operation(any(), TokyoDB.Database.Operation.t()) :: :ok | {:error, atom()}
  def put_operation(client_name, %Operation{} = operation) do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        case Mnesia.match_object({@table, client_name, :_}) do
          [{_, _, operations}] ->
            Mnesia.write({@table, client_name, [operation | operations]})

          [] ->
            {:error, :transaction_not_found}
        end
      end)

    result
  end

  @spec exists?(any()) :: boolean()
  def exists?(client_name) do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        match?([_], Mnesia.match_object({@table, client_name, :_}))
      end)

    result
  end

  @doc false
  @spec decode(tuple()) :: t()
  def decode({@table, client_name, operations}),
    do: %@table{client_name: client_name, operations: operations}

  @doc false
  @spec encode(t()) :: tuple()
  def encode(%@table{client_name: client_name, operations: operations}),
    do: {@table, client_name, operations}

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
