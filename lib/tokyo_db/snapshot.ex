defmodule TokyoDB.Snapshot do
  @moduledoc """
  Manage snapshots of the database.
  """

  @doc """
  Creates and stores a backup of the database.
  """
  @spec create(String.t()) :: :ok
  def create(name) do
    path = build_path(name)
    base_path = Application.fetch_env!(:tokyo_db, :snapshot_dir)
    File.mkdir_p!(base_path)

    :ok = :mnesia.backup(to_charlist(path))
  end

  @doc """
  Reads a stored backup.
  """
  @spec view(String.t()) :: [atom()]
  def view(name) do
    path = build_path(name)

    view_fun = fn
      {:schema, _tab, _create_list}, acc ->
        {[], acc}

      {tab, key, value}, acc ->
        {[tab, key, value], [{tab, key, value} | acc]}
    end

    {:ok, snapshot} =
      :mnesia.traverse_backup(
        to_charlist(path),
        :mnesia_backup,
        :dummy,
        :read_only,
        view_fun,
        []
      )

    Enum.reverse(snapshot)
  end

  @doc """
  Deletes a stored backup.
  """
  @spec delete(String.t()) :: :ok | {:error, atom()}
  def delete(name) do
    path = build_path(name)

    :ok = File.rm(path)
  end

  defp build_path(name) do
    base_path = Application.fetch_env!(:tokyo_db, :snapshot_dir)

    Path.join(base_path, "#{name}.bak")
  end
end
