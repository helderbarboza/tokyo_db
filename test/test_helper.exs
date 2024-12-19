defmodule TestHelpers do
  def create do
    TokyoDB.Database.setup_store()
  end

  def drop do
    :stopped = :mnesia.stop()
    :ok = :mnesia.delete_schema([node()])
  end

  def reset do
    drop()
    create()
  end
end

ExUnit.after_suite(fn _ ->
  TestHelpers.drop()
end)

ExUnit.start()
