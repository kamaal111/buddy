# List available commands
default:
    just --list --unsorted

# Build and run the server
run-server:
    just server/run-build

# Build the server
build-server:
    just server/build

# Stop server
stop-server:
    just server/stop

# Run server in dev mode
dev-server:
    just server/dev

# Tag server image
tag-server-image:
    just server/tag-image

# Push server image
push-server-image:
    just server/push-image

# Test server
test:
    just server/test

quality: quality-server

quality-server:
    just server/quality

# Type check
type-check:
    just server/type-check

# Lint server
lint-server:
    just server/lint

# Lint code
lint: lint-server

# Lint and fix any issues that can be fixed automatically on server
lint-fix-server:
    just server/lint-fix

# Lint and fix any issues that can be fixed automatically
lint-fix: lint-fix-server

# Format code
format:
    just server/format

# Set up dev container. This step runs after building the dev container
post-dev-container-create:
    just .devcontainer/post-create
    just bootstrap

# Bootstrap server
bootstrap-server:
    just server/bootstrap

# Bootstrap project
bootstrap: bootstrap-server
