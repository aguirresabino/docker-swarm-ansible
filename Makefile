# Makefile for Ansible Docker Swarm Project
# ==========================================
# 
# Simplified Makefile that centralizes essential development operations.
# Focus on core workflows: setup, development, testing, deployment, and cleanup.
#
# Usage: make <target>
# Run 'make help' for available targets.

# Variables
# ---------
DOCKER_COMPOSE = docker compose
ANSIBLE_CONTAINER = ansible-control
TEST_CONTAINER = ansible-test

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# Environment Management
# =====================

.PHONY: setup
setup: ## 🚀 Setup complete development environment
	@echo "$(GREEN)Setting up development environment...$(NC)"
	@$(DOCKER_COMPOSE) down --remove-orphans
	@$(DOCKER_COMPOSE) build --no-cache
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Environment ready! Use 'make shell' to access container.$(NC)"

.PHONY: start
start: ## ▶️  Start containers
	@$(DOCKER_COMPOSE) up -d

.PHONY: stop
stop: ## ⏹️  Stop containers
	@$(DOCKER_COMPOSE) down

.PHONY: status
status: ## 📊 Show container status
	@$(DOCKER_COMPOSE) ps

.PHONY: clean
clean: ## 🧹 Clean containers and volumes
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@$(DOCKER_COMPOSE) down --volumes --remove-orphans
	@docker system prune -f

# Development
# ===========

.PHONY: dev
dev: start shell ## 🛠️  Start development (containers + shell)

.PHONY: shell
shell: ## 🐚 Access container shell
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash

.PHONY: logs
logs: ## 📋 Show container logs
	@$(DOCKER_COMPOSE) logs -f

# Testing
# =======

.PHONY: test
test: ## 🧪 Run complete test suite (with test environment)
	@echo "$(GREEN)Starting test environment...$(NC)"
	@$(DOCKER_COMPOSE) --profile testing build ansible-test
	@$(DOCKER_COMPOSE) --profile testing up -d ansible-test
	@echo "$(GREEN)Running complete test suite...$(NC)"
	@$(DOCKER_COMPOSE) --profile testing exec $(TEST_CONTAINER) ansible-lint playbook.yml
	@$(DOCKER_COMPOSE) --profile testing exec $(TEST_CONTAINER) yamllint .
	@$(DOCKER_COMPOSE) --profile testing exec $(TEST_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --syntax-check
	@$(DOCKER_COMPOSE) --profile testing exec $(TEST_CONTAINER) bash -c "cd roles/common && molecule syntax"
	@$(DOCKER_COMPOSE) --profile testing exec $(TEST_CONTAINER) bash -c "cd roles/docker_manager && molecule syntax"
	@$(DOCKER_COMPOSE) --profile testing exec $(TEST_CONTAINER) bash -c "cd roles/docker_worker && molecule syntax"
	@echo "$(GREEN)All tests completed!$(NC)"
	@$(DOCKER_COMPOSE) --profile testing down

.PHONY: lint
lint: ## 🔍 Run linting checks
	@echo "$(GREEN)Running linting...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-lint playbook.yml
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) yamllint .

# Deployment
# ==========

.PHONY: deploy
deploy: ## 🚀 Deploy to all hosts
	@echo "$(GREEN)Deploying to all hosts...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --limit all

.PHONY: deploy-check
deploy-check: ## ✅ Deploy check (dry-run)
	@echo "$(GREEN)Running deployment check...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --limit all --check

.PHONY: deploy-managers
deploy-managers: ## 🚀 Deploy to managers only
	@echo "$(GREEN)Deploying to manager nodes...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --limit managers

.PHONY: deploy-workers
deploy-workers: ## 🚀 Deploy to workers only
	@echo "$(GREEN)Deploying to worker nodes...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --limit workers

# Debugging and Utilities
# ======================

.PHONY: debug
debug: ## 🐛 Debug mode with verbose output
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "export ANSIBLE_STDOUT_CALLBACK=debug && bash"

.PHONY: ping
ping: ## 🏓 Test host connectivity
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible -i inventory/hosts.ini all -m ping

.PHONY: version
version: ## � Show versions
	@echo "$(BLUE)Ansible version:$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible --version
	@echo "$(BLUE)Docker version:$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) docker --version

# Help
# ====

.PHONY: help
help: ## 📚 Show available commands
	@echo "$(GREEN)Docker Swarm Ansible - Available Commands$(NC)"
	@echo "=========================================="
	@echo ""
	@echo "$(BLUE)Environment:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*##.*(🚀|▶️|⏹️|📊|🧹)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Development:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*##.*(🛠️|🐚|📋)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Testing:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*##.*(🧪|🔍)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Deployment:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*##.*(�|✅)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Debug & Utils:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*##.*(🐛|🏓|📋)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Quick Start:$(NC)"
	@echo "  make setup        # Setup environment"
	@echo "  make dev          # Start development"
	@echo "  make test         # Run all tests"
	@echo "  make deploy-check # Test deployment"
	@echo "  make clean        # Clean up"
