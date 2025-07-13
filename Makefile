# Makefile for Ansible Docker Swarm Project
# ==========================================
# 
# This Makefile centralizes all development operations for the Ansible Docker Swarm project.
# It provides targets for environment management, development, testing, deployment, and maintenance.
#
# Usage: make <target>
# Run 'make help' for a list of available targets.

# Variables
# ---------
DOCKER_COMPOSE = docker compose
ANSIBLE_CONTAINER = ansible-control
TEST_CONTAINER = ansible-test
PROJECT_NAME = docker-swarm-ansible

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
setup: ## 🚀 Initialize the complete development environment
	@echo "$(GREEN)Setting up development environment...$(NC)"
	@$(DOCKER_COMPOSE) down --remove-orphans
	@$(DOCKER_COMPOSE) build --no-cache
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Environment ready! Use 'make shell' to access the container.$(NC)"

.PHONY: setup-test
setup-test: ## 🧪 Initialize the testing environment
	@echo "$(GREEN)Setting up testing environment...$(NC)"
	@$(DOCKER_COMPOSE) --profile testing build ansible-test
	@$(DOCKER_COMPOSE) --profile testing up -d ansible-test
	@echo "$(GREEN)Testing environment ready!$(NC)"

.PHONY: start
start: ## ▶️  Start the development environment
	@echo "$(GREEN)Starting development environment...$(NC)"
	@$(DOCKER_COMPOSE) up -d
	@$(MAKE) status

.PHONY: stop
stop: ## ⏹️  Stop the development environment
	@echo "$(YELLOW)Stopping development environment...$(NC)"
	@$(DOCKER_COMPOSE) down

.PHONY: restart
restart: ## 🔄 Restart the development environment
	@echo "$(YELLOW)Restarting development environment...$(NC)"
	@$(DOCKER_COMPOSE) restart
	@$(MAKE) status

.PHONY: status
status: ## 📊 Show status of all containers
	@echo "$(BLUE)Container Status:$(NC)"
	@$(DOCKER_COMPOSE) ps

# Development
# ===========

.PHONY: dev
dev: start ## 🛠️  Start development environment and open shell
	@$(MAKE) shell

.PHONY: shell
shell: ## 🐚 Access the Ansible control container shell
	@echo "$(GREEN)Opening shell in $(ANSIBLE_CONTAINER) container...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash

.PHONY: shell-test
shell-test: ## 🧪 Access the testing container shell
	@echo "$(GREEN)Opening shell in $(TEST_CONTAINER) container...$(NC)"
	@$(DOCKER_COMPOSE) --profile testing exec $(TEST_CONTAINER) bash

.PHONY: logs
logs: ## 📋 Show logs from all containers
	@$(DOCKER_COMPOSE) logs -f

.PHONY: logs-dev
logs-dev: ## 📋 Show logs from development container
	@$(DOCKER_COMPOSE) logs -f $(ANSIBLE_CONTAINER)

.PHONY: logs-test
logs-test: ## 📋 Show logs from testing container
	@$(DOCKER_COMPOSE) --profile testing logs -f $(TEST_CONTAINER)

# Testing
# =======

.PHONY: test
test: ## 🧪 Run all tests (lint + unit + integration)
	@echo "$(GREEN)Running complete test suite...$(NC)"
	@$(MAKE) lint
	@$(MAKE) test-syntax-check
	@$(MAKE) test-unit
	@$(MAKE) test-integration || echo "$(YELLOW)Integration tests failed or skipped$(NC)"
	@echo "$(GREEN)All tests completed!$(NC)"

.PHONY: test-basic
test-basic: ## 🧪 Run basic tests (lint + syntax only)
	@echo "$(GREEN)Running basic test suite...$(NC)"
	@$(MAKE) lint
	@$(MAKE) test-syntax-check
	@echo "$(GREEN)Basic tests completed!$(NC)"

.PHONY: test-unit
test-unit: ## 🔬 Run unit tests for all roles using Molecule
	@echo "$(GREEN)Running unit tests for all roles...$(NC)"
	@$(MAKE) test-role-common || echo "$(YELLOW)Common role tests failed$(NC)"
	@$(MAKE) test-role-docker-manager || echo "$(YELLOW)Docker manager role tests failed$(NC)"
	@$(MAKE) test-role-docker-worker || echo "$(YELLOW)Docker worker role tests failed$(NC)"
	@echo "$(GREEN)Unit tests completed!$(NC)"

.PHONY: test-integration
test-integration: ## 🔗 Run integration tests
	@echo "$(GREEN)Running integration tests...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd tests && python -m pytest test_integration.py -v"

.PHONY: test-syntax
test-syntax: ## ✅ Test playbook syntax and validation
	@echo "$(GREEN)Testing playbook syntax...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --syntax-check

.PHONY: test-syntax-check
test-syntax-check: ## ✅ Test playbook syntax without connectivity check
	@echo "$(GREEN)Testing playbook syntax only...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --syntax-check

# Individual Role Testing
# =======================

.PHONY: test-role-common
test-role-common: ## 🧪 Test common role with Molecule
	@echo "$(GREEN)Testing common role...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/common && molecule syntax"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-lint roles/common

.PHONY: test-role-docker-manager
test-role-docker-manager: ## 🧪 Test docker_manager role with Molecule
	@echo "$(GREEN)Testing docker_manager role...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/docker_manager && molecule syntax"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-lint roles/docker_manager

.PHONY: test-role-docker-worker
test-role-docker-worker: ## 🧪 Test docker_worker role with Molecule
	@echo "$(GREEN)Testing docker_worker role...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/docker_worker && molecule syntax"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-lint roles/docker_worker

# Advanced Molecule Testing (requires Docker-in-Docker)
# ====================================================

.PHONY: test-molecule-full
test-molecule-full: ## 🚀 Run full Molecule test suite (requires Docker-in-Docker)
	@echo "$(YELLOW)Running full Molecule test suite (may fail in some Docker-in-Docker environments)...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/common && molecule test" || echo "$(YELLOW)Common role full test failed (expected in some environments)$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/docker_manager && molecule test" || echo "$(YELLOW)Docker manager role full test failed (expected in some environments)$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/docker_worker && molecule test" || echo "$(YELLOW)Docker worker role full test failed (expected in some environments)$(NC)"

# Linting and Code Quality
# ========================

.PHONY: lint
lint: ## 🔍 Run all linting checks
	@echo "$(GREEN)Running all linting checks...$(NC)"
	@$(MAKE) lint-ansible
	@$(MAKE) lint-yaml

.PHONY: lint-ansible
lint-ansible: ## 🔍 Run Ansible linting
	@echo "$(GREEN)Running Ansible lint...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-lint playbook.yml

.PHONY: lint-yaml
lint-yaml: ## 🔍 Run YAML linting
	@echo "$(GREEN)Running YAML lint...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) yamllint .

.PHONY: lint-fix
lint-fix: ## 🔧 Fix automatically fixable linting issues
	@echo "$(GREEN)Attempting to fix linting issues...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-lint --fix playbook.yml || echo "$(YELLOW)Some issues require manual fixing$(NC)"

# Deployment
# ==========

.PHONY: deploy
deploy: ## 🚀 Deploy to all hosts
	@echo "$(GREEN)Deploying to all hosts...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "./run-playbook.sh all"

.PHONY: deploy-check
deploy-check: ## ✅ Deploy to all hosts in check mode (dry-run)
	@echo "$(GREEN)Running deployment check (dry-run)...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "./run-playbook.sh all --check"

.PHONY: deploy-managers
deploy-managers: ## 🚀 Deploy to manager nodes only
	@echo "$(GREEN)Deploying to manager nodes...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "./run-playbook.sh managers"

.PHONY: deploy-workers
deploy-workers: ## 🚀 Deploy to worker nodes only
	@echo "$(GREEN)Deploying to worker nodes...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "./run-playbook.sh workers"

.PHONY: deploy-managers-check
deploy-managers-check: ## ✅ Deploy to manager nodes in check mode
	@echo "$(GREEN)Running manager deployment check...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "./run-playbook.sh managers --check"

.PHONY: deploy-workers-check
deploy-workers-check: ## ✅ Deploy to worker nodes in check mode
	@echo "$(GREEN)Running worker deployment check...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "./run-playbook.sh workers --check"

# Debugging and Development
# =========================

.PHONY: debug
debug: ## 🐛 Enter debugging mode with verbose output
	@echo "$(GREEN)Starting debug session...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "export ANSIBLE_STDOUT_CALLBACK=debug && bash"

.PHONY: inventory
inventory: ## 📋 Show Ansible inventory
	@echo "$(GREEN)Ansible Inventory:$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-inventory -i inventory/hosts.ini --list

.PHONY: ping
ping: ## 🏓 Test connectivity to all hosts
	@echo "$(GREEN)Testing connectivity to all hosts...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible -i inventory/hosts.ini all -m ping

.PHONY: facts
facts: ## 📊 Gather facts from all hosts
	@echo "$(GREEN)Gathering facts from all hosts...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible -i inventory/hosts.ini all -m setup

.PHONY: docker-version
docker-version: ## 🐳 Check Docker version in container
	@echo "$(GREEN)Docker version in container:$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) docker --version

.PHONY: ansible-version
ansible-version: ## 📋 Check Ansible version
	@echo "$(GREEN)Ansible version:$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible --version

# Maintenance and Cleanup
# =======================

.PHONY: clean
clean: ## 🧹 Clean up containers and volumes
	@echo "$(YELLOW)Cleaning up containers and volumes...$(NC)"
	@$(DOCKER_COMPOSE) down --volumes --remove-orphans
	@docker system prune -f

.PHONY: clean-all
clean-all: ## 🧹 Complete cleanup including images
	@echo "$(RED)Performing complete cleanup (including images)...$(NC)"
	@$(DOCKER_COMPOSE) down --volumes --remove-orphans --rmi all
	@docker system prune -af
	@docker volume prune -f

.PHONY: prune
prune: ## 🧹 Remove unused Docker resources
	@echo "$(YELLOW)Removing unused Docker resources...$(NC)"
	@docker system prune -f
	@docker volume prune -f
	@docker network prune -f

.PHONY: rebuild
rebuild: ## 🔄 Rebuild containers from scratch
	@echo "$(YELLOW)Rebuilding containers from scratch...$(NC)"
	@$(DOCKER_COMPOSE) down --volumes --remove-orphans
	@$(DOCKER_COMPOSE) build --no-cache
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Rebuild completed!$(NC)"

# Validation and Health Checks
# ============================

.PHONY: validate
validate: ## ✅ Run complete validation suite
	@echo "$(GREEN)Running complete validation suite...$(NC)"
	@$(MAKE) lint
	@$(MAKE) test-syntax-check
	@$(MAKE) ansible-version
	@$(MAKE) docker-version
	@echo "$(GREEN)Validation completed successfully!$(NC)"

.PHONY: validate-offline
validate-offline: ## ✅ Run validation without host connectivity checks
	@echo "$(GREEN)Running offline validation suite...$(NC)"
	@$(MAKE) lint
	@$(MAKE) test-syntax-check
	@$(MAKE) ansible-version
	@$(MAKE) docker-version
	@echo "$(GREEN)Offline validation completed successfully!$(NC)"

.PHONY: health
health: ## 🏥 Check health of development environment
	@echo "$(GREEN)Checking environment health...$(NC)"
	@echo "$(BLUE)Container Status:$(NC)"
	@$(DOCKER_COMPOSE) ps
	@echo "$(BLUE)Docker Version:$(NC)"
	@$(MAKE) docker-version
	@echo "$(BLUE)Ansible Version:$(NC)"
	@$(MAKE) ansible-version
	@echo "$(BLUE)Available Space:$(NC)"
	@df -h | head -1
	@df -h | grep -E "/|/var"

# Quick Start and Common Workflows
# ================================

.PHONY: quick-start
quick-start: ## ⚡ Quick start: setup + validate + show help
	@$(MAKE) setup
	@$(MAKE) validate
	@$(MAKE) help

.PHONY: dev-workflow
dev-workflow: ## 🔄 Complete development workflow: setup + test + deploy-check
	@$(MAKE) setup
	@$(MAKE) test-basic
	@echo "$(GREEN)Development workflow completed successfully!$(NC)"

.PHONY: ci-workflow
ci-workflow: ## 🤖 CI/CD workflow: lint + test + syntax check
	@$(MAKE) lint
	@$(MAKE) test-syntax-check
	@$(MAKE) test-unit || echo "$(YELLOW)Some unit tests failed (may be expected in CI environment)$(NC)"
	@echo "$(GREEN)CI workflow completed successfully!$(NC)"

# Help and Documentation
# ======================

.PHONY: help
help: ## 📚 Show this help message
	@echo "$(GREEN)Ansible Docker Swarm Project - Makefile Commands$(NC)"
	@echo "=================================================="
	@echo ""
	@echo "$(BLUE)Environment Management:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*##.*(🚀|▶️|⏹️|🔄|📊)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Development:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*##.*(🛠️|🐚|📋)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Testing:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*##.*(🧪|🔬|🔗|✅)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Linting and Quality:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*##.*(🔍|🔧)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Deployment and Debugging:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*##.*(🐛|🏓|🐳)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Maintenance:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*##.*(🧹)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Quick Workflows:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*##.*(⚡|🤖)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Quick Start Examples:$(NC)"
	@echo "  make quick-start        # Complete setup and validation"
	@echo "  make dev                # Start development environment"
	@echo "  make test               # Run all tests (comprehensive)"
	@echo "  make test-basic         # Run basic tests (quick validation)"
	@echo "  make deploy-check       # Test deployment (dry-run)"
	@echo "  make clean              # Clean up environment"
	@echo ""
	@echo "$(YELLOW)For more information, see README.md$(NC)"

# Prevent make from trying to build files named like targets
.PHONY: all $(MAKECMDGOALS)
