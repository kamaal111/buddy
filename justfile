# List available commands
default:
    just --list --unsorted

# Run server in dev mode
dev-server:
    just server/dev

quality: lint

# Type check
type-check:
    just server/type-check

# Lint code
lint:
    just server/lint

# Lint and fix any issues that can be fixed automatically
lint-fix:
    just server/lint-fix

# Format code
format:
    just server/format

# Set up dev container. This step runs after building the dev container
post-dev-container-create:
    just .devcontainer/post-create
    just bootstrap

# Bootstrap project
bootstrap:
    just server/bootstrap
