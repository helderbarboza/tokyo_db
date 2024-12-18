defmodule TokyoDB.Database.Operation do
  @moduledoc """
  An operation to be used on transaction log.
  """

  defstruct [:type, :value]

  @type t :: %__MODULE__{
          type: :set,
          value: any()
        }

  def build_set(value) do
    %__MODULE__{type: :set, value: value}
  end
end
