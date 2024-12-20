defmodule TokyoDB.Table.TransactionLog do
  @moduledoc """
  Stores the active transactions.
  """

  use GenServer
  alias TokyoDB.Snapshot
  alias TokyoDB.Table.KV
  alias TokyoDB.Table.TransactionLog.Operation
  alias :mnesia, as: Mnesia

  @table __MODULE__

  defstruct [:client_name, :operations]

  @type t :: %__MODULE__{client_name: String.t(), operations: [Operation.t()]}

  @impl true
  def init(state) do
    {:ok, state}
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

  @spec get(any()) :: {:ok, t()} | {:error, atom()}
  def get(client_name) do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        case Mnesia.match_object({@table, client_name, :_}) do
          [item] -> {:ok, decode(item)}
          [] -> {:error, :transaction_not_found}
        end
      end)

    result
  end

  @spec get!(any()) :: t()
  def get!(client_name) do
    case get(client_name) do
      {:ok, item} -> item
      _ -> raise RuntimeError, message: "no transactions found"
    end
  end

  @spec delete(any()) :: :ok | {:error, atom()}
  def delete(client_name) do
    {:atomic, result} =
      Mnesia.transaction(fn ->
        case Mnesia.match_object({@table, client_name, :_}) do
          [item] -> :ok = Mnesia.delete_object(item)
          [] -> {:error, :transaction_not_found}
        end
      end)

    result
  end

  @spec put_operation(any(), Operation.t()) :: :ok | {:error, atom()}
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

  def commit(client_name) do
    transaction_result =
      Mnesia.transaction(fn ->
        case Mnesia.match_object({@table, client_name, :_}) do
          [item] ->
            snapshot = get_kv_snapshot(client_name)

            transaction = decode(item)

            transaction.operations
            |> Enum.reverse()
            |> operation_reducer_recursive(snapshot, client_name)

            :ok = Mnesia.delete({@table, client_name})
            nil

          [] ->
            {:error, :transaction_not_found}
        end
      end)

    case transaction_result do
      {:aborted, {:atomicity_failure, _} = err} ->
        {:atomic, :ok} =
          Mnesia.transaction(fn ->
            Mnesia.delete({@table, client_name})
          end)

        {:error, err}

      {:atomic, result} ->
        {:ok, result}
    end
  end

  defp get_kv_snapshot(client_name) do
    client_name
    |> Snapshot.view()
    |> Enum.filter(fn {tab, _k, _v} -> tab === KV end)
    |> Enum.map(fn item ->
      kv = KV.decode(item)

      {kv.key, kv.value}
    end)
    |> Enum.into(%{})
  end

  defp operation_reducer_recursive([], snapshot_acc, _client_name), do: snapshot_acc

  defp operation_reducer_recursive(
         [%Operation{type: :set, key: key, value: operation_value} | rest],
         snapshot_acc,
         client_name
       ) do
    snapshot_value = Map.get(snapshot_acc, key)
    snapshot_keys = Map.keys(snapshot_acc)

    case Mnesia.match_object({KV, key, :_}) do
      [raw_current_kv] ->
        %{value: current_value} = KV.decode(raw_current_kv)

        cond do
          # key exists in both snapshot and database, and values are the same
          key in snapshot_keys and snapshot_value == current_value ->
            Mnesia.write({KV, key, operation_value})
            updated_snapshot_acc = Map.drop(snapshot_acc, key)
            operation_reducer_recursive(rest, updated_snapshot_acc, client_name)

          # key exists in both snapshot and database, but values differ
          snapshot_value != current_value ->
            Mnesia.abort({:atomicity_failure, key})

          # key exists in the database but not in the snapshot
          key not in snapshot_keys ->
            Mnesia.write({KV, key, operation_value})
            operation_reducer_recursive(rest, snapshot_acc, client_name)
        end

      [] ->
        # key does not exist in the database
        Mnesia.write({KV, key, operation_value})
        operation_reducer_recursive(rest, snapshot_acc, client_name)
    end
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
