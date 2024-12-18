defmodule TokyoDB.Database.TransactionLogTest do
  use ExUnit.Case
  doctest TokyoDB.Database.TransactionLog
  alias TokyoDB.Database.TransactionLog
  alias :mnesia, as: Mnesia

  setup_all do
    :stopped = Mnesia.stop()
    :ok = Mnesia.delete_schema([node()])
    TokyoDB.Database.setup_store()
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
