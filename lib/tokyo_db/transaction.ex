defmodule TokyoDB.Transaction do
  @moduledoc """
  Database transactions management.
  """

  alias TokyoDB.Database.TransactionLog
  alias TokyoDB.Snapshot
  alias TokyoDB.Table.TransactionLog

  @spec begin(any()) :: {:error, atom()} | {:ok, nil}
  def begin(client_name) do
    with :ok <- TransactionLog.insert(client_name) do
      Snapshot.create(client_name)
      {:ok, nil}
    end
  end

  @spec rollback(any()) :: {:error, atom()} | {:ok, nil}
  def rollback(client_name) do
    with :ok <- TransactionLog.delete(client_name) do
      Snapshot.delete(client_name)
      {:ok, nil}
    end
  end

  defdelegate commit(client_name), to: TransactionLog

  defdelegate in_transaction?(client_name), to: TransactionLog, as: :exists?
end
