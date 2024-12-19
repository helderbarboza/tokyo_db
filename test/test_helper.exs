ExUnit.after_suite(fn _ ->
  :stopped = :mnesia.stop()
  :ok = :mnesia.delete_schema([node()])
end)

ExUnit.start()
