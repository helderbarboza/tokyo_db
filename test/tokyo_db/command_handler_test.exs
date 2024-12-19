defmodule TokyoDB.CommandHandlerTest do
  use ExUnit.Case
  alias TokyoDB.CommandHandler, as: CH
  doctest TokyoDB.CommandHandler

  setup do
    TestHelpers.reset()
  end

  describe "handle/2 and handle!/2 from examples" do
    test "BEGIN: assuming the test key does not exist at the beginning of the interaction" do
      assert nil == CH.handle!(:get, ["teste"], "A")
      assert nil == CH.handle!(:get, ["teste"], "B")
      assert nil == CH.handle!(:begin, [], "A")
      assert {nil, 1} == CH.handle!(:set, ["teste", 1], "A")
      assert nil == CH.handle!(:get, ["teste"], "B")
      assert 1 == CH.handle!(:get, ["teste"], "A")
    end

    test "BEGIN: it is not possible to open a transaction within an already ongoing transaction" do
      assert {:ok, nil} == CH.handle(:begin, [], "A")
      assert {:error, :transaction_exists} == CH.handle(:begin, [], "A")
    end

    test "ROLLBACK" do
      assert nil == CH.handle!(:get, ["teste"], "A")
      assert nil == CH.handle!(:get, ["teste"], "B")
      assert nil == CH.handle!(:begin, [], "A")

      # Here, on the example, the expected old value was `false` instead of
      # `nil`. maybe a mistake? 🤷‍♂️
      assert {nil, 1} == CH.handle!(:set, ["teste", 1], "A")
      assert nil == CH.handle!(:get, ["teste"], "B")
      assert 1 == CH.handle!(:get, ["teste"], "A")
      assert nil == CH.handle!(:rollback, [], "A")
      assert nil == CH.handle!(:get, ["teste"], "A")
      assert nil == CH.handle!(:get, ["teste"], "B")
    end
  end

  test "COMMIT: on success, your changes become visible to everyone" do
    assert nil == CH.handle!(:get, ["teste"], "A")
    assert nil == CH.handle!(:get, ["teste"], "B")
    assert nil == CH.handle!(:begin, [], "A")
    assert {nil, 1} == CH.handle!(:set, ["teste", 1], "A")
    assert nil == CH.handle!(:get, ["teste"], "B")
    assert 1 == CH.handle!(:get, ["teste"], "A")
    assert nil == CH.handle!(:commit, [], "A")
    assert 1 == CH.handle!(:get, ["teste"], "A")
    assert 1 == CH.handle!(:get, ["teste"], "B")
  end
end
