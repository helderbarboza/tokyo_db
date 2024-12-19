defmodule TokyoDB.Table.TransactionLogTest do
  use ExUnit.Case
  alias TokyoDB.Table.TransactionLog
  doctest TokyoDB.Table.TransactionLog

  setup do
    TestHelpers.reset()
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
