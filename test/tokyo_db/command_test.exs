defmodule TokyoDB.CommandTest do
  use ExUnit.Case
  doctest TokyoDB.Command
  alias TokyoDB.Command

  describe "parse/1" do
    test ~S|parses `"abcd"` into `"abcd"`| do
      assert Command.parse("abcd") === "abcd"
    end

    test ~S|parses `"a10"` into `"a10"`| do
      assert Command.parse("a10") === "a10"
    end

    test ~S|parses `"\"uma string com espaços\""` into `"uma string com espaços"`| do
      assert Command.parse("\"uma string com espaços\"") === "uma string com espaços"
    end

    test ~S|parses `"\"teste\""` into `"teste"`| do
      assert Command.parse("\"teste\"") === "teste"
    end

    test ~S|parses `"101"` into `101`| do
      assert Command.parse("101") === 101
    end

    test ~S|parses `"3.14"` into `"3.14"`| do
      assert Command.parse("3.14") === "3.14"
    end

    test ~S|parses `"\"TRUE\"" ` into `"TRUE"`| do
      assert Command.parse("\"TRUE\"") === "TRUE"
    end

    test ~S|parses `"TRUE" ` into `true`| do
      assert Command.parse("TRUE") === true
    end

    test ~S|parses `"FALSE" ` into `false`| do
      assert Command.parse("FALSE") === false
    end

    test ~S|parses `"NIL" ` into `nil`| do
      assert Command.parse("NIL") === nil
    end
  end

  describe "split/1" do
    test ~S|splits `"foo"` into `["foo"]`| do
      assert Command.split("foo") === {:ok, ["foo"]}
    end

    test ~S|splits `"\"foo\""` into `["\"foo\""]`| do
      assert Command.split("\"foo\"") === {:ok, ["\"foo\""]}
    end

    test ~S|splits `"foo bar"` into `["foo", "bar"]`| do
      assert Command.split("foo bar") === {:ok, ["foo", "bar"]}
    end

    test ~S|splits `"\"foo bar\""` into `["\"foo bar\""]`| do
      assert Command.split("\"foo bar\"") === {:ok, ["\"foo bar\""]}
    end

    test ~S|splits `"\"foo\" bar"` into `["\"foo\"", "bar"]`| do
      assert Command.split("\"foo\" bar") === {:ok, ["\"foo\"", "bar"]}
    end

    test ~S|splits `"foo \"bar baz\""` into `["foo", "\"bar baz\""]`| do
      assert Command.split("foo \"bar baz\"") === {:ok, ["foo", "\"bar baz\""]}
    end

    test ~S|splits `"\"foo bar\" \"baz qux\""` into `["\"foo bar\"", "\"baz qux\""]`| do
      assert Command.split("\"foo bar\" \"baz qux\"") === {:ok, ["\"foo bar\"", "\"baz qux\""]}
    end

    test ~S|cannot split `"foo\"bar"` because of an unmatched quote`| do
      assert Command.split("foo\"bar") === :error
    end
  end
end
