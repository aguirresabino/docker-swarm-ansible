COMPOSE = docker compose
ANSIBLE_CONTAINER = ansible

.PHONY: setup start stop status clean dev shell logs test lint deploy deploy-check deploy-managers deploy-workers debug ping version

setup: ## Setup development environment
	@$(COMPOSE) down --remove-orphans && $(COMPOSE) build --no-cache && $(COMPOSE) up -d

start: ## Start containers
	@$(COMPOSE) up -d

stop: ## Stop containers
	@$(COMPOSE) down

status: ## Show container status
	@$(COMPOSE) ps

clean: ## Clean containers and volumes
	@$(COMPOSE) down --volumes --remove-orphans && docker system prune -f

dev: start shell ## Start development

shell: ## Access container shell
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) bash

logs: ## Show container logs
	@$(COMPOSE) logs -f

test: ## Run complete test suite
	@echo "Running complete test suite..."
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --syntax-check
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/ntp && molecule test"
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/python-requirements && molecule test"
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/docker && molecule test"
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/docker-swarm-init && molecule test"
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/docker-swarm-manager && molecule test"
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "cd roles/docker-swarm-worker && molecule test"
	@echo "All tests completed!"

lint: ## Run linting checks
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-lint playbook.yml
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) yamllint .

deploy: ## Deploy to all hosts
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --limit all

deploy-check: ## Deploy check (dry-run)
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --limit all --check

deploy-managers: ## Deploy to managers only
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --limit managers

deploy-workers: ## Deploy to workers only
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) ansible-playbook -i inventory/hosts.ini playbook.yml --limit workers

debug: ## Debug mode with verbose output
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) bash -c "export ANSIBLE_STDOUT_CALLBACK=debug && bash"

ping: ## Test host connectivity
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) ansible -i inventory/hosts.ini all -m ping

version: ## Show versions
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) ansible --version
	@$(COMPOSE) exec $(ANSIBLE_CONTAINER) docker --version