defmodule TokyoDBWeb.ErrorText do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on Text requests.

  See config/config.exs.
  """
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
