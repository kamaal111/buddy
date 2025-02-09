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
    just server/bootstrap

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
