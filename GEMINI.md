# Development and Contribution Guide: Ansible for Docker Swarm

## 1. Project Overview

This document specifies the standards for automating a Docker Swarm cluster configuration using Ansible and defines the development protocol to be followed. The project must adhere to the principles of modularity, testability, security, and a structured development workflow.

**Note on `GEMINI.md`:** This file is a specific instruction set for AI assistants like Gemini, Claude, or other AI agents acting as software engineers. It should never be used as part of the project's user-facing documentation. New, specific documentation should be created for the project as needed, and this file should not be linked to or referenced in those documents.

## 2. Project Structure

The repository must follow this structure with comprehensive Molecule testing:

```
.
├── docs/
│   └── plans/
├── inventory/
│   ├── group_vars/
│   │   └── all.yml
│   └── hosts.ini
├── roles/
│   ├── common/
│   │   ├── defaults/
│   │   ├── handlers/
│   │   ├── molecule/
│   │   │   └── default/
│   │   │       ├── molecule.yml
│   │   │       ├── converge.yml
│   │   │       ├── prepare.yml
│   │   │       └── tests/
│   │   │           └── test_common.py
│   │   ├── tasks/
│   │   └── tests/
│   ├── docker_manager/
│   │   └── molecule/
│   │       └── default/
│   │           ├── molecule.yml
│   │           ├── converge.yml
│   │           ├── prepare.yml
│   │           └── tests/
│   │               └── test_docker_manager.py
│   └── docker_worker/
│       └── molecule/
│           └── default/
│               ├── molecule.yml
│               ├── converge.yml
│               ├── prepare.yml
│               └── tests/
│                   └── test_docker_worker.py
├── ssh_keys/
├── tests/
│   ├── requirements.txt
│   └── test_integration.py
├── compose.yml
├── Dockerfile
├── Dockerfile.test
└── playbook.yml
```

- **`docs/plans/`**: Contains the planning artifacts for each development task.
- **`inventory/`**: Host definitions and variables.
- **`roles/`**: Task definitions, separated by node responsibility, each with complete Molecule test suites.
- **`tests/`**: Infrastructure validation tests and test dependencies.
- **`Dockerfile`, `compose.yml`**: Defines the containerized development environment with Docker-in-Docker support.
- **`playbook.yml`**: Main playbook that orchestrates all roles.

## 3. Development Environment

A containerized environment using Docker is mandatory for all development and execution to ensure consistency. The environment supports Docker-in-Docker for Molecule testing.

### 3.1. Dockerfile

The control node image is defined by a multi-stage Dockerfile that includes all necessary tools for execution and testing.

```dockerfile
# Multi-stage build for development and testing

# Base stage with common dependencies
FROM python:3.9-slim as base

# Install system dependencies including Docker CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI for Docker-in-Docker support
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir \
    ansible \
    docker \
    "molecule[docker]" \
    testinfra \
    ansible-lint \
    yamllint \
    pytest \
    pytest-testinfra

# Development stage
FROM base as development
WORKDIR /ansible
COPY . /ansible
CMD ["ansible", "--version"]

# Testing stage with additional test dependencies
FROM base as testing
RUN pip install --no-cache-dir \
    pytest-xdist \
    pytest-cov \
    pytest-html
WORKDIR /ansible
COPY . /ansible
CMD ["molecule", "--version"]
```

### 3.2. Docker Compose

Use the following `compose.yml` to manage the control node container with Docker-in-Docker support.

```yaml
services:
  ansible-control:
    build: 
      context: .
      target: development
    container_name: ansible_control_node
    privileged: true  # Required for Docker-in-Docker and systemd
    volumes:
      - .:/ansible
      - ~/.ssh:/root/.ssh:ro
      - /var/run/docker.sock:/var/run/docker.sock
      - docker_data:/var/lib/docker
    environment:
      - DOCKER_TLS_CERTDIR=
      - DOCKER_HOST=unix:///var/run/docker.sock
    command: tail -f /dev/null

  ansible-test:
    build:
      context: .
      target: testing
    container_name: ansible_test_node
    privileged: true
    volumes:
      - .:/ansible
      - /var/run/docker.sock:/var/run/docker.sock
      - docker_test_data:/var/lib/docker
    environment:
      - DOCKER_TLS_CERTDIR=
      - DOCKER_HOST=unix:///var/run/docker.sock
    profiles:
      - testing
    command: tail -f /dev/null

volumes:
  docker_data:
  docker_test_data:
```

### 3.3. Environment Workflow Commands

**All development operations MUST use the Makefile.**

- **Initialize Environment:**
  ```bash
  make setup
  ```

- **Access Container Shell:**
  ```bash
  make shell
  ```

- **Start Development:**
  ```bash
  make dev
  ```

- **Shutdown Environment:**
  ```bash
  make stop
  ```

## 4. Ansible Configuration

### 4.1. Inventory

The inventory must be modular. Host and group definitions are in `inventory/hosts.ini`.

**Authentication Requirement:** SSH key authentication is mandatory. The `ansible_ssh_private_key_file` variable must be used. For all other secrets, use **Ansible Vault**.

**`inventory/hosts.ini` Example:**
```ini
[managers]
manager1 ansible_host=192.168.1.10 ansible_ssh_private_key_file=~/.ssh/manager1_key

[workers]
worker1 ansible_host=192.168.1.20

[workers:vars]
ansible_ssh_private_key_file=~/.ssh/worker_nodes_key

[all:vars]
ansible_user=your_ssh_user
ansible_python_interpreter=/usr/bin/python3
```

### 4.2. Roles

Automation logic is encapsulated in roles, each with comprehensive Molecule test suites.

- **`common`**: Base configuration applied to all nodes (e.g., install Docker).
- **`docker_manager`**: Initializes the Swarm and manages the manager nodes.
- **`docker_worker`**: Joins the worker nodes to the Swarm.

#### 4.2.1. Role Testing Structure

Each role MUST include a complete Molecule test suite following this standardized structure:

```
roles/<role_name>/
├── defaults/           # Default variables
├── handlers/           # Handlers for service management
├── tasks/             # Main task definitions
├── molecule/          # Molecule test suite
│   └── default/
│       ├── molecule.yml      # Molecule configuration with Docker driver
│       ├── converge.yml      # Playbook to test the role
│       ├── prepare.yml       # System preparation tasks
│       └── tests/
│           └── test_<role>.py # Testinfra test cases
└── tests/             # Additional test files (optional)
```

#### 4.2.2. Molecule Configuration Standards

All Molecule configurations MUST:
- Use the Docker driver for containerized testing
- Use Ubuntu 22.04 as the base test image
- Enable privileged mode for systemd and Docker operations
- Include proper cgroupns_mode and volume mounts for systemd
- Configure Testinfra as the verifier with parallel execution
- Include comprehensive test sequences (lint, syntax, converge, idempotence, verify)

#### 4.2.3. Testinfra Test Standards

All Testinfra tests MUST:
- Test package installations and service states
- Verify configuration file contents and permissions
- Test network connectivity and port availability
- Validate Docker and Swarm functionality where applicable
- Include proper test function documentation
- Handle both positive and negative test cases

### 4.3. Main Playbook (`playbook.yml`)

The main playbook orchestrates the execution of roles.

```yaml
---
- name: Apply common configuration to all nodes
  hosts: all
  become: yes
  roles:
    - common

- name: Configure Docker Swarm Managers
  hosts: managers
  become: yes
  roles:
    - docker_manager

- name: Configure Docker Swarm Workers
  hosts: workers
  become: yes
  roles:
    - docker_worker
```

## 5. Execution and Testing

### 5.1. Makefile Commands

The project includes a simplified Makefile that centralizes essential development operations:

- **Environment Management**: `setup`, `start`, `stop`, `status`, `clean`
- **Development**: `dev`, `shell`, `logs`
- **Testing**: `test`, `lint`
- **Deployment**: `deploy`, `deploy-check`, `deploy-managers`, `deploy-workers`
- **Debug & Utilities**: `debug`, `ping`, `version`

**Essential Commands:**
```bash
make help          # Show all available commands
make setup         # Setup development environment
make dev           # Start development (containers + shell)
make test          # Run complete test suite
make deploy-check  # Test deployment (dry-run)
```

### 5.2. Playbook Execution

All playbook execution is handled directly by the Makefile targets. **No intermediate scripts are used** - all operations execute ansible-playbook commands directly within the containerized environment.

**Usage Examples:**
```bash
# All deployment operations MUST use Makefile
make deploy              # Run on all hosts
make deploy-check        # Run in check mode (dry-run) on all hosts
make deploy-managers     # Run on managers only
make deploy-workers      # Run on workers only
```

### 5.3. Testing Strategy

#### 5.3.1. Multi-Level Testing Approach

The project implements a comprehensive multi-level testing strategy:

1. **Static Analysis (Linting)**
   - `ansible-lint` for playbook and role quality
   - `yamllint` for YAML syntax validation
   - Executed automatically in CI/CD and Molecule tests

2. **Unit Testing (Molecule + Testinfra)**
   - Individual role testing in isolated containers
   - Docker driver for consistent, reproducible environments
   - Testinfra for infrastructure validation
   - Parallel test execution for efficiency

3. **Integration Testing**
   - Full playbook execution against test containers
   - End-to-end workflow validation
   - Multi-node Swarm functionality testing

4. **Idempotence Testing**
   - Automatic verification that roles can be run multiple times
   - Ensures configuration stability and reliability

#### 5.3.2. Test Execution

**All testing operations MUST use the Makefile:**
```bash
# Run complete test suite (automatically manages test environment)
make test

# Run linting only
make lint

# Deploy validation
make deploy-check
```

**The `make test` command automatically:**
- Sets up dedicated test environment
- Runs ansible-lint and yamllint
- Validates playbook syntax  
- Tests all roles with Molecule
- Cleans up test environment

#### 5.3.3. Docker-in-Docker Testing Requirements

All testing relies on Docker-in-Docker capabilities:

- **Container Privileges**: Tests run in privileged containers
- **systemd Support**: Full systemd functionality in test containers
- **Docker Socket Access**: Direct access to Docker daemon
- **Network Isolation**: Each test gets isolated network environment
- **Resource Management**: Proper cleanup of test containers and networks

## 6. Development Protocol and Workflow

### 6.1. Git Workflow

#### Branching Strategy
All changes must be developed in a dedicated branch created from `main`.
- **Naming:** `<type>/<short-description>` (e.g., `feat/add-firewall-role`)

#### Conventional Commits
All commits MUST adhere to the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification.
- **Structure:** `<type>(optional scope): <description>`

### 6.2. AI Operational Protocol

#### Core Principle: The Plan Precedes Action
No Ansible code implementation shall be initiated without a formally defined and registered execution plan in `/docs/plans/`.

#### Documentation Mandate
At the completion of any task, the AI must review all project documentation. If the changes introduced by the task are not accurately reflected in the documentation, the AI must create, update, or amend the documentation to ensure it is current and comprehensive. This includes, but is not limited to, the `README.md`, `docs/`, and any other relevant files.

#### General Process Flow
```mermaid
graph TD
    A[Task Start] --> B{Phase 1: Planning};
    B --> B1[1. Create Plan File];
    B1 --> B2[2. Structure Plan: Objective, Analysis, Scope, Checklist];
    B2 --> C{Phase 2: Execution & Tracking};
    C --> C1["Execution Loop"];
    C1 --> C2["a. Implement Ansible task/role"];
    C2 --> C3["b. Mark [x] on checklist"];
    C3 --> C4["c. Commit (code + plan)"];
    C4 --> C1;
    C1 --> D{Phase 3: Completion Verification};
    D --> D1["Check Criteria:"];
    D1 --> D2["- Checklist 100%?"];
    D2 --> D3["- `ansible-lint` & `molecule test` passed?"];
    D3 --> D4["- Playbook executed successfully?"];
    D4 --> E[Task End];

    style A fill:#d4edda,stroke:#155724
    style E fill:#d4edda,stroke:#155724
    style B fill:#cce5ff,stroke:#004085
    style C fill:#fff3cd,stroke:#856404
    style D fill:#f8d7da,stroke:#721c24
```

#### Phase 1: Planning
**Action**: Before writing code, generate the planning artifact.

1.  **Create Plan File**:
    - **Command**: Create a new Markdown file in `/docs/plans/`.
    - **Naming**: The name of each plan file must be only a number that must follow the sequence.
    - **Example**: `1.md`. If the file `1.md` already exists in `docs/plans`, then a new task must have the name `2.md`.

2.  **Structure the Plan**: The file must contain the sections: `1. Objective`, `2. Technical Analysis and Strategy`, `3. Scope of Modification`, and `4. Execution Plan (Checklist)`.

#### Phase 2: Execution and Tracking
**Action**: Implement the Ansible code following the plan and recording progress.

1.  **Continuous Update**: The plan file must be modified in real-time.
2.  **Progress Logging**: Immediately after completing a subtask, mark it as done: change `- [ ]` to `- [x]`.
3.  **Atomic Version Control**: Make a commit after completing significant subtasks, including the updated plan file.

#### Phase 3: Completion Criteria
**Action**: Verify the following conditions to validate task completion.

A task is declared **COMPLETE** if, and only if, all the following conditions return `TRUE`:

1.  **Checklist Complete**: The checklist in the plan is 100% filled with `[x]`.
2.  **Static Analysis Passed**: All code must pass `ansible-lint` and `yamllint` without errors.
3.  **Molecule Tests Passed**: All roles with Molecule configurations must pass `molecule test` successfully.
4.  **Playbook Validation**: The playbooks must execute in check mode without errors using `make deploy-check`.
5.  **Docker-in-Docker Functionality**: Verify that Molecule can create, manage, and destroy Docker containers.
6.  **Test Coverage**: Each role must have comprehensive Testinfra tests covering all functionality.
7.  **Plan as Proof**: The finalized plan file serves as the execution log and the auditable proof that all steps were followed.

#### Mandatory Testing Protocol for AI Agents

Before declaring any development task complete, AI agents MUST execute the following testing sequence using the Makefile:

**Required Makefile Commands:**
```bash
# Essential validation commands
make test            # Complete test suite (includes lint + syntax + roles)
make deploy-check    # Deployment validation
```

**Testing Environment Requirements:**
- The `make test` command automatically manages test environment setup and cleanup
- All tests run within containerized environment for consistency
- Basic functionality tests MUST pass for task completion
- Docker-in-Docker Molecule tests are enhanced functionality when environment supports it

**Test Failure Protocol:**
- Any basic test failure MUST be resolved before task completion
- Root cause analysis MUST be documented in the plan
- Failed tests MUST be re-executed after fixes
- No task shall be marked complete with failing basic tests

**Docker-in-Docker Limitations:**
- Complex Docker-in-Docker scenarios may have connectivity issues in some environments
- Basic syntax testing and playbook validation are sufficient for development validation
- Full Molecule container testing is enhanced functionality when available