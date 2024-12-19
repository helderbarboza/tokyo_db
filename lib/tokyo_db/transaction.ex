defmodule TokyoDB.Transaction do
  alias TokyoDB.Database.TransactionLog
  alias TokyoDB.Snapshot
  alias TokyoDB.Table.TransactionLog

  @spec begin(any()) :: {:error, atom()} | {:ok, nil}
  def begin(client_name) do
    case TransactionLog.insert(client_name) do
      :ok ->
        Snapshot.create(client_name)
        {:ok, nil}

      {:error, _} = err ->
        err
    end
  end

  @spec rollback(any()) :: {:error, atom()} | {:ok, nil}
  def rollback(client_name) do
    case TransactionLog.delete(client_name) do
      :ok ->
        Snapshot.delete(client_name)
        {:ok, nil}

      {:error, _} = err ->
        err
    end
  end

  def commit(_client_name), do: raise("TODO")

  defdelegate in_transaction?(client_name), to: TransactionLog, as: :exists?
end
