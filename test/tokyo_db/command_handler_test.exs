defmodule TokyoDB.CommandHandlerTest do
  use ExUnit.Case
  alias TokyoDB.CommandHandler, as: CH
  doctest TokyoDB.CommandHandler

  setup do
    TestHelpers.reset()
  end

  describe "tests from the given examples" do
    test "BEGIN: assuming the test key does not exist at the beginning of the interaction" do
      assert match?(%{value: nil}, CH.handle!(%CH{type: :get, args: ["teste"]}, "A"))
      assert match?(%{value: nil}, CH.handle!(%CH{type: :get, args: ["teste"]}, "B"))
      assert match?(nil, CH.handle!(%CH{type: :begin, args: []}, "A"))

      assert match?(
               {%{value: nil}, %{value: 1}},
               CH.handle!(%CH{type: :set, args: ["teste", 1]}, "A")
             )

      assert match?(%{value: nil}, CH.handle!(%CH{type: :get, args: ["teste"]}, "B"))
      assert match?(%{value: 1}, CH.handle!(%CH{type: :get, args: ["teste"]}, "A"))
    end

    test "BEGIN: it is not possible to open a transaction within an already ongoing transaction" do
      assert match?({:ok, nil}, CH.handle(%CH{type: :begin, args: []}, "A"))
      assert match?({:error, :transaction_exists}, CH.handle(%CH{type: :begin, args: []}, "A"))
    end

    test "ROLLBACK" do
      assert match?(%{value: nil}, CH.handle!(%CH{type: :get, args: ["teste"]}, "A"))
      assert match?(%{value: nil}, CH.handle!(%CH{type: :get, args: ["teste"]}, "B"))
      assert match?(nil, CH.handle!(%CH{type: :begin, args: []}, "A"))

      # Here, on the example, the expected old value was `false`
      # instead of `nil`, which IMO seems to be an mistake 🤷‍♂️
      assert match?(
               {%{value: nil}, %{value: 1}},
               CH.handle!(%CH{type: :set, args: ["teste", 1]}, "A")
             )

      assert match?(%{value: nil}, CH.handle!(%CH{type: :get, args: ["teste"]}, "B"))
      assert match?(%{value: 1}, CH.handle!(%CH{type: :get, args: ["teste"]}, "A"))
      assert match?(nil, CH.handle!(%CH{type: :rollback, args: []}, "A"))
      assert match?(%{value: nil}, CH.handle!(%CH{type: :get, args: ["teste"]}, "A"))
      assert match?(%{value: nil}, CH.handle!(%CH{type: :get, args: ["teste"]}, "B"))
    end
  end
end
