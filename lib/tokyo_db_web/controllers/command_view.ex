defmodule TokyoDBWeb.CommandView do
  @moduledoc false

  @actions Enum.map(~w[rollback commit begin], &"#{&1}.text")
  def get(%{result: value}) do
    "#{format_value(value)} "
  end

  def set(%{result: {old_value, new_value}}) do
    "#{format_value(old_value)} #{format_value(new_value)}"
  end

  def render(action, _assigns) when action in @actions do
    "OK"
  end

  def error(assigns) do
    message =
      case assigns.error do
        :transaction_exists ->
          "Already in transaction"

        :transaction_not_found ->
          "Outside of a transaction"

        :unknown_command ->
          "No command #{command_type(assigns.command_line)}"

        :empty_command ->
          "Empty command"

        {:syntax_error, command_type, args} ->
          "#{command_type} #{format_command_args(args)} - Syntax error"

        {:invalid_key_type, key} ->
          "Value #{format_key(key)} is not valid as key"

        {:invalid_value_type, value} ->
          "Cannot SET key to #{format_value(value)}"
      end

    "ERR \"#{message}\""
  end

  defp format_key(term) do
    term
    |> inspect()
    |> String.upcase()
  end

  defp format_value(term) when is_binary(term) do
    term
  end

  defp format_value(term) do
    term
    |> inspect()
    |> String.upcase()
  end

  defp command_type(command_line) do
    command_line
    |> String.split("\s")
    |> List.first()
  end

  defp format_command_args(args) do
    Enum.map_join(args, " ", &"<#{&1}>")
  end
end
