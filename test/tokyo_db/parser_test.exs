defmodule TokyoDB.ParserTest do
  use ExUnit.Case, async: true
  alias TokyoDB.Parser
  doctest TokyoDB.Parser

  describe "parse_token/1" do
    test ~S|parses `"abcd"` into `"abcd"`| do
      assert Parser.parse_token("abcd") === "abcd"
    end

    test ~S|parses `"a10"` into `"a10"`| do
      assert Parser.parse_token("a10") === "a10"
    end

    test ~S|parses `"\"uma string com espaços\""` into `"uma string com espaços"`| do
      assert Parser.parse_token("\"uma string com espaços\"") === "uma string com espaços"
    end

    test ~S|parses `"\"teste\""` into `"teste"`| do
      assert Parser.parse_token("\"teste\"") === "teste"
    end

    test ~S|parses `"101"` into `101`| do
      assert Parser.parse_token("101") === 101
    end

    test ~S|parses `"3.14"` into `"3.14"`| do
      assert Parser.parse_token("3.14") === "3.14"
    end

    test ~S|parses `"\"TRUE\"" ` into `"TRUE"`| do
      assert Parser.parse_token("\"TRUE\"") === "TRUE"
    end

    test ~S|parses `"TRUE" ` into `true`| do
      assert Parser.parse_token("TRUE") === true
    end

    test ~S|parses `"FALSE" ` into `false`| do
      assert Parser.parse_token("FALSE") === false
    end

    test ~S|parses `"NIL" ` into `nil`| do
      assert Parser.parse_token("NIL") === nil
    end
  end

  describe "split/1" do
    test ~S|splits `"foo"` into `["foo"]`| do
      assert Parser.split("foo") === {:ok, ["foo"]}
    end

    test ~S|splits `"\"foo\""` into `["\"foo\""]`| do
      assert Parser.split("\"foo\"") === {:ok, ["\"foo\""]}
    end

    test ~S|splits `"foo bar"` into `["foo", "bar"]`| do
      assert Parser.split("foo bar") === {:ok, ["foo", "bar"]}
    end

    test ~S|splits `"\"foo bar\""` into `["\"foo bar\""]`| do
      assert Parser.split("\"foo bar\"") === {:ok, ["\"foo bar\""]}
    end

    test ~S|splits `"\"foo\" bar"` into `["\"foo\"", "bar"]`| do
      assert Parser.split("\"foo\" bar") === {:ok, ["\"foo\"", "bar"]}
    end

    test ~S|splits `"foo \"bar baz\""` into `["foo", "\"bar baz\""]`| do
      assert Parser.split("foo \"bar baz\"") === {:ok, ["foo", "\"bar baz\""]}
    end

    test ~S|splits `"\"foo bar\" \"baz qux\""` into `["\"foo bar\"", "\"baz qux\""]`| do
      # credo:disable-for-next-line
      assert Parser.split("\"foo bar\" \"baz qux\"") === {:ok, ["\"foo bar\"", "\"baz qux\""]}
    end

    test ~S|cannot split `"foo\"bar"` because of an unmatched quote`| do
      assert Parser.split("foo\"bar") === {:error, :unmatched_quote}
    end
  end
end
