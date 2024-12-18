defmodule TokyoDB.Snapshot do
  @moduledoc """
  Manage snapshots of the database.
  """
  @spec create(charlist()) :: list()
  def create(file_name) do
    path = build_path(file_name)
    base_path = Application.fetch_env!(:tokyo_db, :snapshot_dir)
    File.mkdir_p!(base_path)

    :mnesia.backup(path)
    view(file_name)
  end

  @spec view(charlist()) :: list()
  def view(file_name) do
    path = build_path(file_name)

    view_fun = fn
      {:schema, _tab, _create_list}, acc ->
        {[], acc}

      {tab, key, value}, acc ->
        {[tab, key, value], [[tab, key, value] | acc]}
    end

    {:ok, snapshot} =
      :mnesia.traverse_backup(
        path,
        :mnesia_backup,
        :dummy,
        :read_only,
        view_fun,
        []
      )

    Enum.reverse(snapshot)
  end

  @spec delete(charlist()) :: :ok | {:error, atom()}
  def delete(file_name) do
    path = build_path(file_name)

    File.rm(path)
  end

  defp build_path(file_name) do
    base_path = Application.fetch_env!(:tokyo_db, :snapshot_dir)

    base_path
    |> Path.join(file_name)
    |> to_charlist()
  end
end
