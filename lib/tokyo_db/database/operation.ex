defmodule TokyoDB.Database.Operation do
  @moduledoc """
  An operation to be used on transaction log.
  """

  defstruct [:type, :key, :value]

  @type t :: %__MODULE__{
          type: :set,
          key: any(),
          value: any()
        }

  @spec build_set(any(), any()) :: t()
  def build_set(key, value) do
    %__MODULE__{type: :set, key: key, value: value}
  end
end
