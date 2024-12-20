defmodule TokyoDB.SnapshotTest do
  use ExUnit.Case
  alias TokyoDB.Snapshot
  alias TokyoDB.Table.KV
  doctest TokyoDB.Snapshot

  setup do
    TestHelpers.reset()
  end

  describe "create/1" do
    test "creates a snapshot" do
      assert :ok = Snapshot.create("john")
    end
  end

  describe "view/1" do
    test "view stored data" do
      client_name = "john"
      value = "bar"
      {:ok, {_, ^value}} = KV.set("foo", value, client_name)

      assert :ok = Snapshot.create(client_name)

      assert [kv] = Snapshot.view(client_name)
      assert ^value = KV.decode(kv).value
    end
  end
end
