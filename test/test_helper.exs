defmodule TestHelpers do
  @snapshot_dir Application.compile_env!(:tokyo_db, :snapshot_dir)

  def create do
    TokyoDB.Database.setup_store()
  end

  def drop do
    :stopped = :mnesia.stop()
    :ok = :mnesia.delete_schema([node()])
    delete_backups()
  end

  def reset do
    drop()
    create()
  end

  def delete_backups do
    @snapshot_dir
    |> File.ls!()
    |> Enum.filter(&(&1 =~ ~r/\.bak$/))
    |> Enum.map(&Path.join(@snapshot_dir, &1))
    |> Enum.each(&File.rm!/1)
  end
end

ExUnit.after_suite(fn _ ->
  TestHelpers.drop()
end)

ExUnit.start()
