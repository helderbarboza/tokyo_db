defmodule TokyoDB.Snapshot do
  @moduledoc """
  Manage snapshots of the database.
  """
  @spec create(String.t()) :: list()
  def create(name) do
    path = build_path(name)
    base_path = Application.fetch_env!(:tokyo_db, :snapshot_dir)
    File.mkdir_p!(base_path)

    :mnesia.backup(path)
    view(name)
  end

  @spec view(String.t(), function()) :: [atom()]
  def view(name, decode_fun \\ & &1) do
    path = build_path(name)

    view_fun = fn
      {:schema, _tab, _create_list}, acc ->
        {[], acc}

      {tab, key, value}, acc ->
        {[tab, key, value], [decode_fun.({tab, key, value}) | acc]}
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

  @spec delete(String.t()) :: :ok | {:error, atom()}
  def delete(name) do
    path = build_path(name)

    File.rm(path)
  end

  defp build_path(name) do
    base_path = Application.fetch_env!(:tokyo_db, :snapshot_dir)

    Path.join(base_path, "#{name}.bak")
  end
end
