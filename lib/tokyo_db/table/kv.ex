defmodule TokyoDB.Table.KV do
  @moduledoc """
  A `:mnesia` store for key-value data.
  """

  use GenServer
  require Logger
  alias TokyoDB.Snapshot
  alias TokyoDB.Table.TransactionLog
  alias TokyoDB.Table.TransactionLog.Operation
  alias :mnesia, as: Mnesia

  @table __MODULE__

  defstruct [:key, :value]

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t() | integer() | boolean() | nil
        }

  defguardp is_key(value) when is_binary(value) and byte_size(value) > 0

  defguardp is_value(value)
            when is_boolean(value) or is_binary(value) or is_integer(value)

  @impl true
  def init(state) do
    {:ok, state}
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @doc """
  Fetches a KV pair.

  If there is no results, a default KV is returned instead, having `nil` as the
  value.
  """
  @spec get(String.t(), any()) :: {:ok, t()}
  def get(key, _client_name) when not is_key(key) do
    {:error, {:invalid_key_type, key}}
  end

  def get(key, client_name) when is_key(key) do
    do_get(key, client_name, TransactionLog.exists?(client_name))
  end

  @doc """
  Sets the KV pair.

  Returns `{old_kv, new_kv}`. If there is no old state before the update,
  a default KV is returned instead, having `nil` as the value.
  """
  @spec set(String.t(), boolean() | String.t() | integer(), String.t()) :: {:ok, {t(), t()}}
  def set(key, _value, _client_name) when not is_key(key) do
    {:error, {:invalid_key_type, key}}
  end

  def set(_key, value, _client_name) when not is_value(value) do
    {:error, {:invalid_value_type, value}}
  end

  def set(key, value, client_name) when is_key(key) and is_value(value) do
    do_set(key, value, client_name, TransactionLog.exists?(client_name))
  end

  defp do_get(key, client_name, in_transaction)

  defp do_get(key, _client_name, false) do
    result =
      Mnesia.transaction(fn ->
        Mnesia.match_object({@table, key, :_})
      end)

    case result do
      {:atomic, []} ->
        {:ok, decode({@table, key, nil})}

      {:atomic, [item]} ->
        {:ok, decode(item)}
    end
  end

  defp do_get(key, client_name, true) do
    %TransactionLog{operations: operations} = TransactionLog.get!(client_name)
    computed = Operation.compute(operations)

    case Map.get(computed, key) do
      nil ->
        result =
          Mnesia.transaction(fn ->
            Mnesia.match_object({@table, key, :_})
          end)

        case result do
          {:atomic, []} ->
            {:ok, decode({@table, key, nil})}

          {:atomic, [item]} ->
            {:ok, decode(item)}
        end

      value ->
        {:ok, decode({@table, key, value})}
    end
  end

  defp do_set(key, value, client_name, in_transaction)

  defp do_set(key, value, _client_name, false) do
    result =
      Mnesia.transaction(fn ->
        old =
          case Mnesia.match_object({@table, key, :_}) do
            [] -> {@table, key, nil}
            [old] -> old
          end

        :ok = Mnesia.write({@table, key, value})
        [new] = Mnesia.match_object({@table, key, :_})

        {old, new}
      end)

    case result do
      {:atomic, {old, new}} ->
        {:ok, {decode(old), decode(new)}}
    end
  end

  defp do_set(key, value, client_name, true) do
    %TransactionLog{operations: operations} = TransactionLog.get!(client_name)
    computed = Operation.compute(operations)

    old =
      case Map.get(computed, key) do
        nil ->
          client_name
          |> Snapshot.view()
          |> Enum.find(&match?({@table, ^key, _value}, &1))

        value ->
          {@table, key, value}
      end

    :ok = TransactionLog.put_operation(client_name, Operation.build_set(key, value))

    {:ok, {decode(old), decode({@table, key, value})}}
  end

  @doc false
  @spec decode(tuple()) :: t()
  def decode({@table, key, value}),
    do: %@table{key: key, value: value}

  @doc false
  @spec encode(t()) :: tuple()
  def encode(%@table{key: key, value: value}),
    do: {@table, key, value}

  @doc false
  def create_table do
    case Mnesia.create_table(@table,
           attributes: [:key, :value],
           disc_only_copies: [node()]
         ) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, @table}} -> :ok
    end
  end
end
