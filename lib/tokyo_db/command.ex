defmodule TokyoDB.Command do
  @digits_only_pattern ~r/^\d+$/
  @unscaped_quotes_pattern ~r/((?<!\\)")/
  @tokens_pattern ~r/"([^"\\]*(\\.)?)*"|\S+/

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

  @spec split(String.t()) :: {:ok, [String.t()]} | :error
  def split(string) do
    quotes_count =
      @unscaped_quotes_pattern
      |> Regex.scan(string, capture: :first)
      |> Enum.count()

    if rem(quotes_count, 2) === 0 do
      @tokens_pattern
      |> Regex.scan(string, capture: :first)
      |> List.flatten()
      |> then(&{:ok, &1})
    else
      :error
    end
  end
end
