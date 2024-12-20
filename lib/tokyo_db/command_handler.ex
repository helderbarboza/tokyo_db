defmodule TokyoDB.CommandHandler do
  @moduledoc """
  Handles incoming database commands and dispatches to their corresponding
  specific handlers.
  """

  alias TokyoDB.Table.KV
  alias TokyoDB.Transaction

  @command_map [
    {"GET", :get, [:key]},
    {"SET", :set, [:key, :value]},
    {"BEGIN", :begin, []},
    {"COMMIT", :commit, []},
    {"ROLLBACK", :rollback, []}
  ]

  @typedoc "Command-arguments tuple."
  @type ca :: {atom(), [any()]}

  @doc """
  Builds a command struct.
  """
  @spec new(any()) :: {:error, :unknown_command} | {:ok, ca()}
  @spec new(any(), any()) :: {:error, :unknown_command} | {:ok, ca()}
  def new(cmd, arg_names \\ [])

  # credo:disable-for-next-line
  for {string, atom, _arg_names} <- @command_map do
    def new(unquote(string), args) do
      {:ok, {unquote(atom), args}}
    end
  end

  def new(_cmd, _arg_names), do: {:error, :unknown_command}

  @doc """
  Dispatches the structured command to their corresponding specific handler.
  """
  @spec handle(atom(), [any()], String.t()) :: {:ok, any()} | {:error, any()}
  def handle(cmd, args, client_name)

  def handle(:get, [key], client_name) do
    KV.get(key, client_name)
  end

  def handle(:set, [key, value], client_name) do
    KV.set(key, value, client_name)
  end

  def handle(:begin, [], client_name) do
    Transaction.begin(client_name)
  end

  def handle(:commit, [], client_name) do
    Transaction.commit(client_name)
  end

  def handle(:rollback, [], client_name) do
    Transaction.rollback(client_name)
  end

  # Catches all function clauses, returning syntax error
  # credo:disable-for-next-line
  for {string, atom, args} <- @command_map do
    def handle(unquote(atom), _args, _client_name) do
      {:error, {:syntax_error, unquote(string), unquote(args)}}
    end
  end

  @doc """
  Similar to `handle/2` but takes any error returned from the dispatched
  function and raises a `RuntimeError`.
  """
  @spec handle!(atom(), [any()], String.t()) :: any()
  def handle!(cmd, args, client_name) do
    case handle(cmd, args, client_name) do
      {:ok, result} ->
        result

      {:error, reason} ->
        raise RuntimeError, message: "Command execution failed: #{inspect(reason)}"
    end
  end
end
