defmodule TokyoDB.Database.KV do
  @moduledoc "A `:mnesia` store for key-value data"

  use GenServer
  require Logger
  alias :mnesia, as: Mnesia

  defstruct [:key, :value]

  @type key :: String.t()
  @type value :: String.t() | integer() | boolean() | nil

  @type t :: %__MODULE__{key: key, value: value}

  defguardp is_key(value) when is_binary(value) and byte_size(value) > 0

  defguardp is_value(value)
            when is_boolean(value) or is_binary(value) or is_integer(value)

  @impl true
  def init(state) do
    setup_store()

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
        Mnesia.match_object({__MODULE__, key, :_})
      end)

    case result do
      {:atomic, []} ->
        decode({__MODULE__, key, nil})

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
        old_list = Mnesia.match_object({__MODULE__, key, :_})
        :ok = Mnesia.write({__MODULE__, key, value})
        new_list = Mnesia.match_object({__MODULE__, key, :_})

        {old_list, new_list}
      end)

    {
      decode(List.first(old_list, {__MODULE__, key, nil})),
      decode(List.first(new_list, {__MODULE__, key, nil}))
    }
  end

  @spec decode(tuple()) :: t()
  def decode({__MODULE__, key, value}),
    do: %__MODULE__{key: key, value: value}

  @spec encode(t()) :: tuple()
  def encode(%__MODULE__{key: key, value: value}),
    do: {__MODULE__, key, value}

  defp setup_store do
    Logger.debug("Setting up store...")

    :ok = ensure_schema_exists()
    :ok = Mnesia.start()
    :ok = ensure_table_exists()

    Logger.debug("...Store set up!")
  end

  defp ensure_schema_exists do
    case Mnesia.create_schema([node()]) do
      {:error, {_node, {:already_exists, __node}}} -> :ok
      :ok -> :ok
    end
  end

  defp ensure_table_exists do
    case Mnesia.create_table(__MODULE__,
           attributes: [:key, :value],
           disc_only_copies: [node()]
         ) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, __MODULE__}} -> :ok
    end

    :ok = Mnesia.wait_for_tables([__MODULE__], 5000)
  end
end
