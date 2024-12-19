defmodule TokyoDB.TransactionTest do
  use ExUnit.Case
  alias TokyoDB.Transaction
  doctest TokyoDB.Transaction

  setup do
    TestHelpers.reset()
  end

  describe "begin/1" do
    test "creates a transaction" do
      assert {:ok, _} = Transaction.begin("jim")
    end

    test "trying to have two open transactions at the same time returns an error" do
      assert {:ok, _} = Transaction.begin("michael")
      assert {:error, :transaction_exists} = Transaction.begin("michael")
    end

    test "creates a transaction with multiple clients" do
      assert {:ok, _} = Transaction.begin("client_a")
      assert {:ok, _} = Transaction.begin("client_b")
      assert {:ok, _} = Transaction.begin("client_c")
    end
  end

  describe "rollback/1" do
    test "rolls back the active transaction" do
      {:ok, _} = Transaction.begin("client")
      assert {:ok, _} = Transaction.rollback("client")
    end

    test "trying to roll back without having a active transaction returns an error" do
      assert {:error, :transaction_not_found} = Transaction.rollback("client")
    end

    test "rolling back the transaction should not affect others clients" do
      {:ok, _} = Transaction.begin("client_a")
      {:ok, _} = Transaction.begin("client_b")
      {:ok, _} = Transaction.begin("client_c")

      assert {:ok, _} = Transaction.rollback("client_a")

      refute Transaction.in_transaction?("client_a")
      assert Transaction.in_transaction?("client_b")
      assert Transaction.in_transaction?("client_c")
    end
  end
end
