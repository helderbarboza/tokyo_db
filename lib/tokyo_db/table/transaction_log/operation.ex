defmodule TokyoDB.Table.TransactionLog.Operation do
  @moduledoc """
  A structure for individual operations within the transaction log.
  """

  defstruct [:type, :key, :value]

  @type t :: %__MODULE__{
          type: :set,
          key: String.t(),
          value: any()
        }

  @spec build_set(String.t(), any()) :: t()
  def build_set(key, value) do
    %__MODULE__{type: :set, key: key, value: value}
  end

  @spec compute([t()]) :: map()
  def compute(operations) do
    operations
    |> Enum.reverse()
    |> do_compute(%{})
  end

  defp do_compute([], acc) do
    acc
  end

  defp do_compute([%__MODULE__{type: :set, key: key, value: value} | t], acc) do
    do_compute(t, Map.put(acc, key, value))
  end
end
