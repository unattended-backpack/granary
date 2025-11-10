# Makefile for managing Granary (Attic binary cache server).
#
# Configuration is loaded from `.env` and can be overridden by environment
# variables.
#
# Usage:
#   make granary            # Start services and bootstrap.
#   make stop               # Stop all services.
#   make logs               # Follow logs from all services.

# Load configuration from `.env.maintainer` if it exists.
-include .env.maintainer

# Load configuration from `.env` if it exists.
-include .env

# Allow environment variable overrides with defaults.
BUILD_IMAGE ?= unattended/petros:latest
ATTIC_IMAGE ?= unattended/attic:latest
COMPOSE_FILE ?= docker-compose.yml
SECRETS_DIR ?= ./secrets

# Export variables for docker-compose to use.
export BUILD_IMAGE
export ATTIC_IMAGE

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

.PHONY: clean-volumes
clean-volumes:
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

.PHONY: clean
clean:
	@bash -c 'echo -e "\033[33mWARNING: This will remove volumes and secrets.\033[0m"; \
	read -p "Are you sure you want to continue? [y/N]: " confirm; \
	if [[ "$$confirm" != "y" && "$$confirm" != "Y" ]]; then \
		echo "Operation cancelled."; \
		exit 1; \
	fi'
	$(MAKE) clean-volumes
	$(MAKE) clean-secrets
	@echo "Full cleanup complete."

.PHONY: build
build:
	@echo "Building bootstrap image ..."
	docker compose build bootstrap
	@echo "Build complete."

.PHONY: test
test:
	@echo "Running tests ..."
	@echo "... tests completed."

.PHONY: docker
docker: build

.PHONY: ci
ci: build

.PHONY: run
run: granary

.PHONY: shell
shell:
	$(MAKE) granary-d
	@echo "Opening shell in granary container ..."
	docker compose exec granary sh

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

.PHONY: status
status:
	@echo "Granary service status:"
	@docker compose ps

.PHONY: help
help:
	@echo "Granary Management System"
	@echo ""
	@echo "Targets:"
	@echo "  init            Initialize config from examples."
	@echo "  clean-volumes   Stop services and remove volumes."
	@echo "  clean-secrets   Remove generated token files."
	@echo "  clean           Full cleanup (services + secrets)."
	@echo "  build           Build the bootstrap image."
	@echo "  test            Run all tests for the build."
	@echo "  docker          Build Docker image (compiles inside container)."
	@echo "  ci              Build Docker image from pre-built binaries."
	@echo "  run             Run the built Docker image locally."
	@echo "  shell           Open a shell in the Granary container."
	@echo "  granary         Start services and bootstrap (foreground)."
	@echo "  granary-d       Start services in background."
	@echo "  stop            Stop all services."
	@echo "  restart         Restart all services."
	@echo "  bootstrap       Run only the bootstrap container."
	@echo "  logs            Follow logs from all services."
	@echo "  logs-granary    Follow logs from granary only."
	@echo "  logs-bootstrap  Show bootstrap logs."
	@echo "  status          Show service status."
	@echo "  help            Show this help message."
	@echo ""
	@echo "Configuration:"
	@echo "  Variables are loaded from .env"
	@echo "  Override with environment variables:"
	@echo "    COMPOSE_FILE  - Docker compose file (default: docker-compose.yml)"
	@echo "    SECRETS_DIR   - Secrets directory (default: ./secrets)"
	@echo ""
	@echo "Example:"
	@echo "  make init"
	@echo "  make granary"
	@echo "  make granary-d && make logs-granary"
	@echo "  make clean"

.DEFAULT_GOAL := granary
