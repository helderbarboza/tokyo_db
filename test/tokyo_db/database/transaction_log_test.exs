defmodule TokyoDB.Table.TransactionLogTest do
  use ExUnit.Case
  alias TokyoDB.Database
  alias TokyoDB.Table.TransactionLog
  alias :mnesia, as: Mnesia
  doctest TokyoDB.Table.TransactionLog

  setup do
    :stopped = Mnesia.stop()
    :ok = Mnesia.delete_schema([node()])
    Database.setup_store()
  end

  describe "insert/1" do
    test "creates a transaction with success" do
      assert :ok = TransactionLog.insert("michael")
    end

    test "trying to create twice returns error" do
      assert :ok = TransactionLog.insert("dwight")
      assert {:error, :transaction_exists} = TransactionLog.insert("dwight")
    end
  end
end
