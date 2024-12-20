# TokyoDB

TokyoDB is a database that provides a Key-Value store with ACID transaction guarantees built with Phoenix Framework.

## Prerequisites

The application requires:
- Erlang/OTP 27.2
- Elixir 1.17.3

The application uses `asdf` for version management. Make sure you have `asdf` installed and run:

```bash
asdf install
```

## Running the Application

To start the TokyoDB server:

```bash
# Start the Phoenix server
mix phx.server

# Or run it inside IEx (Interactive Elixir)
iex -S mix phx.server
```

The server will be available at [`localhost:4444`](http://localhost:4444).

## API

The application exposes a single endpoint `POST /`, which handles all database commands. It can be used like this:

```bash
curl -H 'X-Client-Name: A' -X POST -d 'SET ABC 1' localhost:4444
```

## Development

### Running Tests

```bash
mix test
```

### Code Quality

To run static code analysis with Credo:

```bash
mix credo
# For strict mode
mix credo --strict
```

### Documentation

To generate documentation:

```bash
mix docs
```