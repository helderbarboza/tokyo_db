defmodule TokyoDB.CommandHandlerTest do
  use ExUnit.Case
  alias TokyoDB.CommandHandler, as: CH
  doctest TokyoDB.CommandHandler

  setup do
    TestHelpers.reset()
  end

  describe "handle/2 and handle!/2 from examples" do
    test "BEGIN: assuming the test key does not exist at the beginning of the interaction" do
      assert match?(%{value: nil}, CH.handle!(:get, ["teste"], "A"))
      assert match?(%{value: nil}, CH.handle!(:get, ["teste"], "B"))
      assert match?(nil, CH.handle!(:begin, [], "A"))
      assert match?({%{value: nil}, %{value: 1}}, CH.handle!(:set, ["teste", 1], "A"))

      assert match?(%{value: nil}, CH.handle!(:get, ["teste"], "B"))
      assert match?(%{value: 1}, CH.handle!(:get, ["teste"], "A"))
    end

    test "BEGIN: it is not possible to open a transaction within an already ongoing transaction" do
      assert match?({:ok, nil}, CH.handle(:begin, [], "A"))
      assert match?({:error, :transaction_exists}, CH.handle(:begin, [], "A"))
    end

    test "ROLLBACK" do
      assert match?(%{value: nil}, CH.handle!(:get, ["teste"], "A"))
      assert match?(%{value: nil}, CH.handle!(:get, ["teste"], "B"))
      assert match?(nil, CH.handle!(:begin, [], "A"))

      # Here, on the example, the expected old value was `false`
      # instead of `nil`, which IMO seems to be an mistake 🤷‍♂️
      assert match?({%{value: nil}, %{value: 1}}, CH.handle!(:set, ["teste", 1], "A"))
      assert match?(%{value: nil}, CH.handle!(:get, ["teste"], "B"))
      assert match?(%{value: 1}, CH.handle!(:get, ["teste"], "A"))
      assert match?(nil, CH.handle!(:rollback, [], "A"))
      assert match?(%{value: nil}, CH.handle!(:get, ["teste"], "A"))
      assert match?(%{value: nil}, CH.handle!(:get, ["teste"], "B"))
    end
  end
end
