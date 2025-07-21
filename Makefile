# Variables
# ---------
DOCKER_COMPOSE = docker compose
ANSIBLE_CONTAINER = ansible

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

# Environment Management
# =====================

.PHONY: setup
setup: ## Setup complete development environment
	@echo "$(GREEN)Setting up development environment...$(NC)"
	@$(DOCKER_COMPOSE) down --remove-orphans
	@$(DOCKER_COMPOSE) build --no-cache
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Environment ready! Use 'make shell' to access container.$(NC)"

.PHONY: start
start: ## Start containers
	@$(DOCKER_COMPOSE) up -d

.PHONY: stop
stop: ## Stop containers
	@$(DOCKER_COMPOSE) down

.PHONY: status
status: ## Show container status
	@$(DOCKER_COMPOSE) ps

.PHONY: clean
clean: ## Clean containers and volumes
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@$(DOCKER_COMPOSE) down --volumes --remove-orphans
	@docker system prune -f

# Development
# ===========

.PHONY: dev
dev: start shell ## Start development (containers + shell)

.PHONY: shell
shell: ## Access container shell
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash

.PHONY: logs
logs: ## Show container logs
	@$(DOCKER_COMPOSE) logs -f

# Testing
# =======

.PHONY: test
test: ## Run complete test suite
	@echo "$(GREEN)Running complete test suite...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --syntax-check
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/common && molecule test"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/python-requirements && molecule test"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/docker && molecule test"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/docker-swarm-init && molecule test"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/docker-swarm-manager && molecule test"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/docker-swarm-worker && molecule test"
	@echo "$(GREEN)All tests completed!$(NC)"

.PHONY: lint
lint: ## Run linting checks
	@echo "$(GREEN)Running linting...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-lint playbook.yml
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) yamllint .

# Deployment
# ==========

.PHONY: deploy
deploy: ## Deploy to all hosts
	@echo "$(GREEN)Deploying to all hosts...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --limit all

.PHONY: deploy-check
deploy-check: ## Deploy check (dry-run)
	@echo "$(GREEN)Running deployment check...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --limit all --check

.PHONY: deploy-managers
deploy-managers: ## Deploy to managers only
	@echo "$(GREEN)Deploying to manager nodes...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --limit managers

.PHONY: deploy-workers
deploy-workers: ## Deploy to workers only
	@echo "$(GREEN)Deploying to worker nodes...$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --limit workers

# Debugging and Utilities
# ======================

.PHONY: debug
debug: ## Debug mode with verbose output
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "export ANSIBLE_STDOUT_CALLBACK=debug && bash"

.PHONY: ping
ping: ## Test host connectivity
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible -i inventory/hosts.ini all -m ping

.PHONY: version
version: ## Show versions
	@echo "$(BLUE)Ansible version:$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) ansible --version
	@echo "$(BLUE)Docker version:$(NC)"
	@$(DOCKER_COMPOSE) exec $(ANSIBLE_CONTAINER) docker --version