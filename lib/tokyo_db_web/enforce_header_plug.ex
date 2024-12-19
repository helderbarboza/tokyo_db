defmodule TokyoDBWeb.EnforceHeaderPlug do
  @moduledoc """
  Plug to ensure that requests include the `"x-client-name"` header.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [text: 2]

  def init(default), do: default

  def call(conn, _default) do
    case get_req_header(conn, "x-client-name") do
      [client_name | _] ->
        assign(conn, :client_name, client_name)

      [] ->
        conn
        |> put_status(:bad_request)
        |> text("Missing required header: x-client-name")
        |> halt()
    end
  end
end
