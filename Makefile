# Makefile for managing Granary (Attic binary cache server).
#
# Configuration is loaded from `.env` and can be overridden by environment
# variables.
#
# Usage:
#   make granary            # Start services and bootstrap.
#   make stop               # Stop all services.
#   make logs               # Follow logs from all services.

# Load configuration from `.env` if it exists.
-include .env

# Allow environment variable overrides with defaults.
COMPOSE_FILE ?= docker-compose.yml
SECRETS_DIR ?= ./secrets

.PHONY: init
init:
	@echo "Initializing configuration files ..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env from .env.example - please review."; \
	else \
		echo ".env already exists."; \
	fi
	@if [ ! -f server.toml ]; then \
		cp server.toml.example server.toml; \
		echo "Created server.toml from server.toml.example - please review."; \
	else \
		echo "server.toml already exists."; \
	fi
	@echo "Initialization complete. Review configuration before running."

.PHONY: granary
granary:
	@echo "Starting Granary services ..."
	docker compose up --build

.PHONY: granary-d
granary-d:
	@echo "Starting Granary services in detached mode ..."
	docker compose up --build -d
	@echo "Services started. Use 'make logs' to view output."

.PHONY: stop
stop:
	@echo "Stopping Granary services ..."
	docker compose down

.PHONY: restart
restart: stop granary

.PHONY: build
build:
	@echo "Building bootstrap image ..."
	docker compose build bootstrap
	@echo "Build complete."

.PHONY: bootstrap
bootstrap:
	@echo "Running bootstrap container ..."
	docker compose up --build bootstrap
	@echo "Bootstrap complete."

.PHONY: logs
logs:
	@echo "Following logs (Ctrl+C to exit) ..."
	docker compose logs -f

.PHONY: logs-granary
logs-granary:
	@echo "Following granary logs (Ctrl+C to exit) ..."
	docker compose logs -f granary

.PHONY: logs-bootstrap
logs-bootstrap:
	@echo "Showing bootstrap logs ..."
	docker compose logs bootstrap

.PHONY: clean
clean:
	@echo "Cleaning up containers and volumes ..."
	docker compose down -v
	@echo "Cleanup complete."

.PHONY: clean-secrets
clean-secrets:
	@echo "Removing generated secrets ..."
	@if [ -d "$(SECRETS_DIR)" ]; then \
		rm -rf $(SECRETS_DIR)/*; \
		echo "Secrets removed from $(SECRETS_DIR)."; \
	else \
		echo "No secrets directory found."; \
	fi

.PHONY: clean-all
clean-all: clean clean-secrets
	@echo "Full cleanup complete."

.PHONY: status
status:
	@echo "Granary service status:"
	@docker compose ps

.PHONY: shell-granary
shell-granary:
	@echo "Opening shell in granary container ..."
	docker compose exec granary sh

.PHONY: help
help:
	@echo "Granary Management System"
	@echo ""
	@echo "Targets:"
	@echo "  init            Initialize config from examples (.env, server.toml)."
	@echo "  granary         Start services and bootstrap (foreground)."
	@echo "  granary-d       Start services in background."
	@echo "  stop            Stop all services."
	@echo "  restart         Restart all services."
	@echo "  build           Rebuild the bootstrap image."
	@echo "  bootstrap       Run only the bootstrap container."
	@echo "  logs            Follow logs from all services."
	@echo "  logs-granary    Follow logs from granary only."
	@echo "  logs-bootstrap  Show bootstrap logs."
	@echo "  clean           Stop services and remove volumes."
	@echo "  clean-secrets   Remove generated token files."
	@echo "  clean-all       Full cleanup (services + secrets)."
	@echo "  status          Show service status."
	@echo "  shell-granary   Open shell in granary container."
	@echo "  help            Show this help message."
	@echo ""
	@echo "Configuration:"
	@echo "  Variables are loaded from .env"
	@echo "  Override with environment variables:"
	@echo "    COMPOSE_FILE  - Docker compose file (default: docker-compose.yml)"
	@echo "    SECRETS_DIR   - Secrets directory (default: ./secrets)"
	@echo ""
	@echo "Example:"
	@echo "  make init       # First time setup"
	@echo "  make granary"
	@echo "  make granary-d && make logs-granary"
	@echo "  make clean-all"

.DEFAULT_GOAL := granary
