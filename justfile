set export
set dotenv-load

PORT := "8080"

# List available commands
default:
    just --list --unsorted

# Run server in dev mode
dev: prepare
    #!/bin/zsh

    export DEBUG="true"

    pnpm run dev

# Type check
type-check:
    pnpm run type-check

# Lint code
lint: type-check
    pnpm run lint

# Lint and fix any issues that can be fixed automatically
lint-fix: type-check
    pnpm run lint-fix

# Format code
format:
    pnpm run format

# Install modules
install-modules:
    #!/bin/zsh

    . ~/.zshrc

    pnpm i

# Set up dev container. This step runs after building the dev container
post-dev-container-create:
    just .devcontainer/post-create
    just bootstrap

# Prepare project to work with
prepare: install-modules

# Bootstrap project
bootstrap: install-node install-pnpm prepare

[private]
install-node:
    #!/bin/zsh

    curl -fsSL https://fnm.vercel.app/install | bash

    . ~/.zshrc

    fnm completions --shell zsh
    fnm install

[private]
install-pnpm:
    #!/bin/zsh

    . ~/.zshrc

    corepack enable pnpm
    corepack use pnpm@latest-10
