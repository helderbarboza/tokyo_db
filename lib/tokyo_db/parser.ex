defmodule TokyoDB.Parser do
  @moduledoc """
  Command parsing tools.
  """
  alias TokyoDB.CommandHandler

  @digits_only_pattern ~r/^\d+$/
  @unscaped_quotes_pattern ~r/((?<!\\)")/
  @tokens_pattern ~r/"([^"\\]*(\\.)?)*"|\S+/

  @type token :: boolean() | nil | String.t() | integer()

  @doc """
  Parses the given command line into a `TokyoDB.CommandHandler` struct.

      iex> Parser.parse("GET \\"The answer\\"")
      {:ok, %TokyoDB.CommandHandler{type: :get, args: ["The answer"]}}

      iex> Parser.parse("SET 1 2 3")
      {:ok, %TokyoDB.CommandHandler{type: :set, args: [1, 2, 3]}}

      iex> Parser.parse("SET \\"I'm\\"Wrong!\\"")
      {:error, :unmatched_quote}

      iex> Parser.parse("INFO")
      {:error, :unknown_command}

      iex> Parser.parse("   ")
      {:error, :empty_command}

  """
  @spec parse(binary()) ::
          {:error, :unknown_command | :unmatched_quote} | {:ok, CommandHandler.t()}
  def parse(string) do
    case split_and_parse_tokens(string) do
      {:ok, [command | args]} ->
        CommandHandler.new(String.upcase(command), args)

      {:ok, []} ->
        {:error, :empty_command}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Parses a token using the corresponding type.

      iex> Parser.parse_token("TRUE")
      true

      iex> Parser.parse_token("\\"TRUE\\"")
      "TRUE"

      iex> Parser.parse_token("true")
      "true"

      iex> Parser.parse_token("NIL")
      nil

      iex> Parser.parse_token("Parkour!")
      "Parkour!"

      iex> Parser.parse_token("Michael Scarn")
      "Michael Scarn"

      iex> Parser.parse_token("360")
      360

      iex> Parser.parse_token("1.61803")
      "1.61803"

  """
  @spec parse_token(String.t()) :: token()
  def parse_token(string)
  def parse_token("TRUE"), do: true
  def parse_token("FALSE"), do: false
  def parse_token("NIL"), do: nil

  def parse_token(string) when is_binary(string) do
    if string =~ @digits_only_pattern do
      String.to_integer(string)
    else
      string
      |> String.replace(@unscaped_quotes_pattern, "")
      |> String.replace(~S|\"|, ~S|"|)
    end
  end

  @doc """
  Splits a command into a list of tokens.

      iex> Parser.split("GET count_of_jokes_told")
      {:ok, ["GET", "count_of_jokes_told"]}

      iex> Parser.split("PUT next_prank \\"put stuff on Jell-o\\"")
      {:ok, ["PUT", "next_prank", "\\"put stuff on Jell-o\\""]}

      iex> Parser.split("UPDATE \\"wrong\\"quotes\\"")
      {:error, :unmatched_quote}

  """
  @spec split(String.t()) :: {:ok, [String.t()]} | {:error, :unmatched_quote}
  def split(string) do
    quotes_count =
      @unscaped_quotes_pattern
      |> Regex.scan(string, capture: :first)
      |> Enum.count()

    case rem(quotes_count, 2) do
      0 ->
        @tokens_pattern
        |> Regex.scan(string, capture: :first)
        |> List.flatten()
        |> then(&{:ok, &1})

      _ ->
        {:error, :unmatched_quote}
    end
  end

  defp split_and_parse_tokens(string) do
    with {:ok, [h | t]} <- split(string) do
      {:ok, [h | Enum.map(t, &parse_token/1)]}
    end
  end
end
