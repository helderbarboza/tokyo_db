defmodule TokyoDBWeb.Router do
  use TokyoDBWeb, :router

  pipeline :api do
    plug :accepts, ["text/plain"]
    plug :put_format, "text"
    plug TokyoDBWeb.EnforceHeaderPlug
    plug :assign_command_line
  end

  scope "/", TokyoDBWeb do
    pipe_through :api

    post "/", CommandController, :run
  end

  def assign_command_line(conn, _opts) do
    conn.body_params
    |> Map.keys()
    |> List.first()
    |> then(&assign(conn, :command_line, &1))
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:tokyo_db, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: TokyoDBWeb.Telemetry
    end
  end
end
