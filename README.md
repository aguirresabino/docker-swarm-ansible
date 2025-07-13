# Ansible for Docker Swarm

This project provides Ansible playbooks to automate the configuration of a Docker Swarm cluster.

## Getting Started

This guide provides instructions on how to set up the development environment and run the Ansible playbooks to configure a Docker Swarm cluster.

### Prerequisites

- Docker
- Docker Compose
- Make (GNU Make)

### Quick Start with Makefile

The project includes a comprehensive Makefile that centralizes all development operations. For a complete setup and validation:

```bash
make quick-start
```

This command will:
1. Set up the complete development environment
2. Run validation tests
3. Display available commands

### Development Environment Setup

**All development operations must use the Makefile.**

```bash
# Set up and start the development environment
make setup

# Start development and open shell
make dev

# Check environment status
make status

# Stop the environment
make stop
```

## Running Playbooks

**All playbook execution must use the Makefile.**

```bash
# Deploy to all hosts
make deploy

# Test deployment (dry-run)
make deploy-check

# Deploy to specific groups
make deploy-managers
make deploy-workers
```

## Testing

### Comprehensive Testing

```bash
# Run all tests (lint + unit + integration)
make test

# Run basic tests (lint + syntax only) - quick validation
make test-basic

# Run individual test types
make lint                # Linting checks
make test-unit          # Unit tests for all roles
make test-integration   # Integration tests
make test-syntax        # Playbook syntax validation
```

### Role-Specific Testing

```bash
# Test individual roles
make test-role-common
make test-role-docker-manager
make test-role-docker-worker
```

### Advanced Testing

```bash
# Full Molecule test suite (requires Docker-in-Docker)
make test-molecule-full

# Validation suite
make validate

# Environment health check
make health
```

## Development Workflows

### Daily Development

```bash
# Start development session
make dev

# Run tests during development
make test

# Check deployment before pushing
make deploy-check
```

### Complete Development Workflow

```bash
# Run the complete development workflow
make dev-workflow
```

This includes: setup → test → deploy-check

### Debugging

```bash
# Enter debugging mode
make debug

# Check connectivity to hosts
make ping

# View inventory
make inventory

# Gather facts from hosts
make facts
```

## Maintenance

```bash
# Clean up containers and volumes
make clean

# Complete cleanup including images
make clean-all

# Remove unused Docker resources
make prune

# Rebuild everything from scratch
make rebuild
```

## Available Makefile Commands

Run `make help` to see all available commands organized by category:

- **Environment Management**: setup, start, stop, restart, status
- **Development**: dev, shell, logs, debug
- **Testing**: test, test-unit, test-integration, lint
- **Deployment**: deploy, deploy-check, deploy-managers, deploy-workers
- **Debugging**: ping, inventory, facts, docker-version
- **Maintenance**: clean, clean-all, prune, rebuild
- **Quick Workflows**: quick-start, dev-workflow, ci-workflow

### Common Command Examples

```bash
make help              # Show all available commands
make quick-start       # Complete setup and validation
make dev               # Start development environment
make test              # Run all tests (comprehensive)
make test-basic        # Run basic tests (quick validation)
make deploy-check      # Test deployment (dry-run)
make clean             # Clean up environment
```

## Project Structure

```
.
├── docs/
│   └── plans/                     # Development planning artifacts
├── inventory/
│   ├── group_vars/
│   │   └── all.yml               # Global variables
│   └── hosts.ini                 # Host definitions
├── roles/
│   ├── common/                   # Base configuration for all nodes
│   │   ├── defaults/
│   │   ├── handlers/
│   │   ├── molecule/
│   │   │   └── default/
│   │   │       ├── molecule.yml
│   │   │       ├── converge.yml
│   │   │       ├── prepare.yml
│   │   │       └── tests/
│   │   │           └── test_common.py
│   │   └── tasks/
│   ├── docker_manager/           # Docker Swarm manager configuration
│   │   └── molecule/
│   │       └── default/
│   │           ├── molecule.yml
│   │           ├── converge.yml
│   │           ├── prepare.yml
│   │           └── tests/
│   │               └── test_docker_manager.py
│   └── docker_worker/            # Docker Swarm worker configuration
│       └── molecule/
│           └── default/
│               ├── molecule.yml
│               ├── converge.yml
│               ├── prepare.yml
│               └── tests/
│                   └── test_docker_worker.py
├── ssh_keys/                     # SSH keys for host authentication
├── tests/
│   ├── requirements.txt          # Test dependencies
│   └── test_integration.py       # Integration test suite
├── Makefile                      # Central automation commands
├── compose.yml                   # Docker Compose configuration
├── Dockerfile                    # Multi-stage container build
├── run-playbook.sh              # Internal script used by Makefile
└── playbook.yml                 # Main orchestration playbook
```

## Key Features

- **🚀 Comprehensive Makefile**: Centralized automation with 40+ commands for all development operations
- **🐳 Containerized Development**: Complete Docker-based environment with Docker-in-Docker support  
- **🧪 Comprehensive Testing**: Multi-level testing with Molecule, Testinfra, and static analysis
- **📋 Role-based Architecture**: Modular Ansible roles for different node types
- **🔧 Quality Assurance**: Integrated linting with ansible-lint and yamllint
- **📚 Rich Documentation**: Detailed guides for both users and AI agents
