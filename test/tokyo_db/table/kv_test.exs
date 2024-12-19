defmodule TokyoDB.Table.KVTest do
  use ExUnit.Case
  alias TokyoDB.Table.KV
  alias TokyoDB.Table.TransactionLog
  alias TokyoDB.Table.TransactionLog.Operation
  alias :mnesia, as: Mnesia
  doctest TokyoDB.Table.KV

  setup do
    TestHelpers.reset()
  end

  describe "get/2 without transaction" do
    test "gets a KV with the existing stored value" do
      key = "foo"
      value = "bar"
      write!(KV, key, value)

      assert {:ok, %KV{key: ^key, value: ^value}} = KV.get(key, "angela")
    end

    test "gets a KV with `nil` as value when no match found" do
      key = "foo"

      assert {:ok, %KV{key: ^key, value: nil}} = KV.get(key, "creed")
    end

    test "gets a KV after the same key being updated twice" do
      key = "foo"
      value_before = "first"
      value_after = "second"

      write!(KV, key, value_before)
      write!(KV, key, value_after)
      assert {:ok, %KV{key: ^key, value: ^value_after}} = KV.get(key, "jim")
    end

    test "gets a KV after other key being updated" do
      key_a = "key_a"
      key_b = "key_b"
      value_a = "value_a"
      value_b = "value_b"

      write!(KV, key_a, value_a)
      write!(KV, key_b, value_b)
      assert {:ok, %KV{key: ^key_a, value: ^value_a}} = KV.get(key_a, "oscar")
    end
  end

  describe "set/3 without transaction" do
    test "sets a new KV" do
      key = "foo"
      value = "bar"

      assert {:ok,
              {
                %KV{key: ^key, value: nil},
                %KV{key: ^key, value: ^value}
              }} = KV.set(key, value, "ryan")
    end

    test "sets an already existing KV" do
      key = "foo"
      value_before = "bar"
      value_after = "qux"

      write!(KV, key, value_before)

      assert {:ok,
              {
                %KV{key: ^key, value: ^value_before},
                %KV{key: ^key, value: ^value_after}
              }} = KV.set(key, value_after, "stanley")
    end

    test "tries to set a value using invalid types" do
      assert {:error, {:invalid_value_type, _}} = KV.set("foo", ~c"bar", "meredith")
      assert {:error, {:invalid_value_type, _}} = KV.set("foo", %{}, "pam")
      assert {:error, {:invalid_value_type, _}} = KV.set("foo", [], "kevin")
    end
  end

  describe "get/2 with transaction" do
    test "gets a unchanged value that has been set before the transaction" do
      key = "key"
      value = "value"
      client = "darryl"

      # Sets a KV
      write!(KV, key, value)

      # Sets a transaction log with no operations
      write!(TransactionLog, client, [])

      assert {:ok, %KV{key: ^key, value: ^value}} = KV.get(key, client)
    end

    test "gets a the last value for a key that has been set inside of own transaction" do
      key = "key"
      value_before = "value_before"
      value_after = "value_after"
      client = "kelly"

      # Sets a KV before
      write!(KV, key, value_before)

      # Sets a transaction log with no operations
      write!(TransactionLog, client, [Operation.build_set(key, value_after)])

      assert {:ok, %KV{key: ^key, value: ^value_after}} = KV.get(key, client)
    end

    test "gets a unchanged value outside of a transaction, while another client updates it inside their transaction" do
      key = "key"
      value_before = "value_before"
      value_after = "value_after"
      client_a = "phyllis"
      client_b = "david"

      # Sets a KV before
      write!(KV, key, value_before)

      # Sets a transaction log for client B with a set operation
      write!(TransactionLog, client_b, [Operation.build_set(key, value_after)])

      assert {:ok, %KV{key: ^key, value: ^value_before}} = KV.get(key, client_a)
    end

    test "each client sees only their own changes inside their transactions" do
      key = "key"
      value_before = "value_before"
      value_after_a = "value_after_a"
      value_after_b = "value_after_b"
      client_a = "roy"
      client_b = "hide"
      client_c = "toby"

      # Sets a KV before
      write!(KV, key, value_before)

      # Sets transaction logs for both clients
      write!(TransactionLog, client_a, [Operation.build_set(key, value_after_a)])
      write!(TransactionLog, client_b, [Operation.build_set(key, value_after_b)])

      # Assert that each client sees their own changes
      assert {:ok, %KV{key: ^key, value: ^value_after_a}} = KV.get(key, client_a)
      assert {:ok, %KV{key: ^key, value: ^value_after_b}} = KV.get(key, client_b)

      # Assert that clients outside transaction still see the original value
      assert {:ok, %KV{key: ^key, value: ^value_before}} = KV.get(key, client_c)
    end
  end

  defp write!(table, key, value) do
    {:atomic, _} =
      Mnesia.transaction(fn ->
        :ok = Mnesia.write({table, key, value})
      end)

    :ok
  end
end
