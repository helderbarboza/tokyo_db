defmodule TokyoDB.CommandHandler do
  alias TokyoDB.Table.KV
  alias TokyoDB.Transaction

  @command_map [
    {"GET", :get, [:key]},
    {"SET", :set, [:key, :value]},
    {"BEGIN", :begin, []},
    {"COMMIT", :commit, []},
    {"ROLLBACK", :rollback, []}
  ]

  defstruct [:type, :args]

  @type t :: %__MODULE__{type: atom(), args: [any()]}

  @doc """
  Builds a command struct.
  """
  @spec new(any()) :: {:error, :unknown_command} | {:ok, t()}
  @spec new(any(), any()) :: {:error, :unknown_command} | {:ok, t()}
  def new(type, args \\ [])

  for {string, atom, _arity} <- @command_map do
    def new(unquote(string), args) do
      {:ok, %__MODULE__{type: unquote(atom), args: args}}
    end
  end

  def new(_type, _args), do: {:error, :unknown_command}

  @spec handle(t(), String.t()) :: {:ok, any()} | {:error, any()}
  def handle(command_handler, client_name)

  def handle(%{type: :get, args: [key]}, client_name) do
    KV.get(key, client_name)
  end

  def handle(%{type: :set, args: [key, value]}, client_name) do
    KV.set(key, value, client_name)
  end

  def handle(%{type: :begin, args: []}, client_name) do
    Transaction.begin(client_name)
  end

  def handle(%{type: :commit, args: []}, client_name) do
    Transaction.commit(client_name)
  end

  def handle(%{type: :rollback, args: []}, client_name) do
    Transaction.rollback(client_name)
  end

  # Catches all function clauses, returning syntax error
  for {string, atom, args} <- @command_map do
    def handle(%{type: unquote(atom), args: _}, _client_name) do
      {:error, {:syntax_error, unquote(string), unquote(args)}}
    end
  end

  def handle!(command_handler, client_name) do
    case handle(command_handler, client_name) do
      {:ok, result} ->
        result

      {:error, reason} ->
        raise RuntimeError, message: "Command execution failed: #{inspect(reason)}"
    end
  end
end
