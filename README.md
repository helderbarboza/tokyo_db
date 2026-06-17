# TokyoDB

[![Elixir CI](https://github.com/user/tokyo_db/actions/workflows/elixir.yml/badge.svg)](https://github.com/user/tokyo_db/actions/workflows/elixir.yml)
![Elixir 1.17.3](https://img.shields.io/badge/elixir-1.17.3-purple)
![Erlang OTP 27.2](https://img.shields.io/badge/erlang-27.2-red)

TokyoDB is a Key-Value database with ACID transaction guarantees, built with Phoenix Framework and backed by Mnesia. It exposes a plain-text protocol over HTTP, supporting CRUD operations and transactional semantics via optimistic concurrency control.

## Technology Stack

| Layer         | Technology                  | Version |
| ------------- | --------------------------- | ------- |
| Language      | Elixir                      | 1.17.3  |
| Runtime       | Erlang/OTP                  | 27.2    |
| Web Framework | Phoenix                     | 1.7.18  |
| HTTP Server   | Bandit                      | 1.5     |
| Storage       | Mnesia (embedded Erlang DB) | —       |
| JSON          | Jason                       | 1.2     |
| Metrics       | Telemetry Metrics + Poller  | 1.x     |
| Clustering    | DNSCluster                  | 0.1.1   |
| Dashboard     | LiveDashboard               | 0.8.3   |

**Dev/Test only:** Credo (static analysis), ExCoveralls (coverage), ExDoc (documentation).

## Architecture

TokyoDB follows a simple pipeline architecture:

```
Client (curl/HTTP) → POST / (X-Client-Name) → Parser → CommandHandler → Mnesia Tables
```

- **HTTP Layer** (`TokyoDBWeb`): A single `POST /` endpoint receives plain-text commands. An `EnforceHeaderPlug` requires the `X-Client-Name` header for client identification.
- **Parser** (`TokyoDB.Parser`): Tokenizes the raw command string using regex, supporting quoted strings, integers, and special keywords (`TRUE`, `FALSE`, `NIL`).
- **CommandHandler** (`TokyoDB.CommandHandler`): Maps parsed commands (`GET`, `SET`, `BEGIN`, `COMMIT`, `ROLLBACK`) to the appropriate module.
- **Storage** (`TokyoDB.Table.KV`): Mnesia `disc_only_copies` table for persistent key-value storage.
- **Transactions**: Optimistic concurrency control using Mnesia snapshots:
  - `BEGIN` — creates a Mnesia backup snapshot + transaction log entry
  - Reads within a transaction merge snapshot state with uncommitted operations
  - `COMMIT` — replays operations, detecting atomicity failures (keys modified by other clients since snapshot)
  - `ROLLBACK` — discards snapshot and transaction log

## Getting Started

### Prerequisites

- **asdf** version manager ([install guide](https://asdf-vm.com/))
- Erlang/OTP 27.2
- Elixir 1.17.3

```bash
# Install correct Erlang & Elixir versions
asdf install

# Fetch dependencies
mix deps.get

# Start the server
mix phx.server
```

The server is available at [localhost:4444](http://localhost:4444) in development.

### Quick Start

```bash
# Set a key
curl -H 'X-Client-Name: A' -X POST -d 'SET name Alice' localhost:4444

# Get a key
curl -H 'X-Client-Name: A' -X POST -d 'GET name' localhost:4444

# Transactions
curl -H 'X-Client-Name: A' -X POST -d 'BEGIN' localhost:4444
curl -H 'X-Client-Name: A' -X POST -d 'SET name Bob' localhost:4444
curl -H 'X-Client-Name: A' -X POST -d 'COMMIT' localhost:4444
```

## Project Structure

```
tokyo_db/
├── config/                  # Environment configuration
│   ├── config.exs           # Shared config
│   ├── dev.exs              # Development (port 4444)
│   ├── prod.exs             # Production
│   ├── runtime.exs          # Runtime env vars
│   └── test.exs             # Test (port 4002)
├── lib/
│   ├── tokyo_db/            # Core database logic
│   │   ├── application.ex           # OTP application
│   │   ├── database.ex              # Mnesia schema & table setup
│   │   ├── command_handler.ex       # Command dispatch
│   │   ├── parser.ex                # Command string parser
│   │   ├── transaction.ex           # Transaction lifecycle
│   │   ├── snapshot.ex              # Mnesia snapshot management
│   │   └── table/
│   │       ├── kv.ex                # Key-value store (Mnesia)
│   │       ├── transaction_log.ex   # Active transactions
│   │       └── transaction_log/
│   │           └── operation.ex     # Operation struct
│   └── tokyo_db_web/        # Web layer
│       ├── endpoint.ex
│       ├── router.ex
│       ├── telemetry.ex
│       ├── enforce_header_plug.ex
│       └── controllers/
│           ├── command_controller.ex
│           ├── command_view.ex
│           └── error_text.ex
├── test/                    # Test suite
│   ├── test_helper.exs
│   ├── support/conn_case.ex
│   └── tokyo_db|tokyo_db_web/
├── priv/                    # Static assets
├── doc/                     # Generated documentation
├── mix.exs                  # Project definition & deps
└── .tool-versions           # asdf versions
```

## API Reference

All commands are sent as `POST /` with plain-text body and `X-Client-Name` header.

| Command             | Example          | Description                |
| ------------------- | ---------------- | -------------------------- |
| `GET <key>`         | `GET name`       | Retrieve a value           |
| `SET <key> <value>` | `SET name Alice` | Set a key-value pair       |
| `BEGIN`             | `BEGIN`          | Start a transaction        |
| `COMMIT`            | `COMMIT`         | Commit current transaction |
| `ROLLBACK`          | `ROLLBACK`       | Abort current transaction  |

**Client isolation:** Each `X-Client-Name` has its own transaction state. Transactions are committed only if no atomicity conflict is detected since the snapshot was taken.

## Development

### Running Tests

```bash
mix test
```

### Code Quality

```bash
mix credo          # Static analysis
mix credo --strict # Strict mode
```

### Test Coverage

```bash
mix coveralls            # Summary
mix coveralls.html       # HTML report
mix coveralls.lcov       # LCOV export
```

### Documentation

```bash
mix docs                 # Generate ExDoc HTML docs
```

## Testing

- **Framework:** ExUnit
- **Approach:** Tests use the real Mnesia database with a `TestHelpers.reset/0` pattern that drops and recreates the schema before each test, ensuring full isolation without mocking.
- **Doctests:** Several modules (`Parser`, `CommandHandler`, `Transaction`, `Table.KV`, `TransactionLog`, `Snapshot`) include doctests verified inline.
- **Coverage:** ExCoveralls configured with LCOV output.

Seven test files cover: command parsing, handler dispatch, transaction lifecycle, snapshot management, KV operations (with and without transactions), transaction log inserts, and error page rendering.

## CI/CD

The project uses GitHub Actions (`.github/workflows/elixir.yml`):

- **Triggers:** Push and PR to `master`
- **Steps:** `mix deps.get` → `mix test`
- **Caching:** Hex dependencies cached via `mix.lock` hash

## Coding Standards

- **Formatter:** Standard Phoenix `.formatter.exs` config (imports `:phoenix` conventions)
- **Analysis:** Credo with strict mode available
- **Style:** Follows Elixir community conventions with `@spec` annotations on public functions

## Contributing

1. Fork the repository
2. Create a feature branch from `master`
3. Write tests for any new functionality
4. Ensure all tests pass: `mix test`
5. Run Credo: `mix credo --strict`
6. Generate coverage report: `mix coveralls`
7. Submit a pull request

Refer to existing code exemplars in each module — the codebase follows consistent patterns for error handling (`{:ok, value}` / `{:error, reason}` tuples), Mnesia operations, and Phoenix controller/view separation.

## License

This project is not yet licensed.
