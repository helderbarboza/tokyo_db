defmodule TokyoDBWeb.ErrorTextTest do
  use TokyoDBWeb.ConnCase

  test "renders 404" do
    assert TokyoDBWeb.ErrorText.render("404.text", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert TokyoDBWeb.ErrorText.render("500.text", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
