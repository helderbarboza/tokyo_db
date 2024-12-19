defmodule TokyoDBWeb.CommandController do
  @moduledoc """
  Entry point for database commands.
  """

  use TokyoDBWeb, :controller

  alias TokyoDB.CommandHandler
  alias TokyoDB.Parser

  def run(conn, _params) do
    %{command_line: command_line, client_name: client_name} = conn.assigns

    with {:ok, {cmd, args}} <- Parser.parse(command_line),
         {:ok, result} <- CommandHandler.handle(cmd, args, client_name) do
      render(conn, cmd.type, result: result)
    else
      {:error, error} ->
        conn
        |> put_status(:internal_server_error)
        |> render(:error, error: error)
    end
  end
end
