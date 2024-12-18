defmodule TokyoDB.Database.KV do
  @moduledoc "A `:mnesia` store for key-value data"

  use GenServer
  require Logger
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
  @spec get(binary()) :: t()
  def get(key) when is_key(key) do
    result =
      Mnesia.transaction(fn ->
        Mnesia.match_object({@table, key, :_})
      end)

    case result do
      {:atomic, []} ->
        decode({@table, key, nil})

      {:atomic, [item]} ->
        decode(item)

      {:atomic, list} when is_list(list) ->
        raise "expected zero or one results but got #{length(list)}"
    end
  end

  @doc """
  Sets the KV pair.

  Returns `{old_kv, new_kv}`. If there is no old state before the update,
  a default KV is returned instead, having `nil` as the value.
  """
  @spec set(binary(), boolean() | binary() | integer()) :: {t(), t()}
  def set(key, value) when is_key(key) and is_value(value) do
    {:atomic, {old_list, new_list}} =
      Mnesia.transaction(fn ->
        old_list = Mnesia.match_object({@table, key, :_})
        :ok = Mnesia.write({@table, key, value})
        new_list = Mnesia.match_object({@table, key, :_})

        {old_list, new_list}
      end)

    {
      decode(List.first(old_list, {@table, key, nil})),
      decode(List.first(new_list, {@table, key, nil}))
    }
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
