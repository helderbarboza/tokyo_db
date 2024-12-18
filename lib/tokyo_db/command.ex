defmodule TokyoDB.Command do
  @moduledoc """
  Command decoding tools.
  """

  @digits_only_pattern ~r/^\d+$/
  @unscaped_quotes_pattern ~r/((?<!\\)")/
  @tokens_pattern ~r/"([^"\\]*(\\.)?)*"|\S+/

  @doc """
  Parses a token using the corresponding type.

    iex> Command.parse("TRUE")
    true

    iex> Command.parse("\\"TRUE\\"")
    "TRUE"

    iex> Command.parse("true")
    "true"

    iex> Command.parse("NIL")
    nil

    iex> Command.parse("Parkour!")
    "Parkour!"

    iex> Command.parse("Michael Scarn")
    "Michael Scarn"

    iex> Command.parse("360")
    360

    iex> Command.parse("1.61803")
    "1.61803"

  """
  @spec parse(String.t()) :: boolean() | nil | String.t() | integer()
  def parse(string)
  def parse("TRUE"), do: true
  def parse("FALSE"), do: false
  def parse("NIL"), do: nil

  def parse(string) when is_binary(string) do
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

    iex> Command.split("GET count_of_jokes_told")
    {:ok, ["GET", "count_of_jokes_told"]}

    iex> Command.split("PUT next_prank \\"put stuff on Jell-o\\"")
    {:ok, ["PUT", "next_prank", "\\"put stuff on Jell-o\\""]}

    iex> Command.split("UPDATE \\"wrong\\"quotes\\"")
    :error

  """
  @spec split(String.t()) :: {:ok, [String.t()]} | :error
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
        :error
    end
  end
end
