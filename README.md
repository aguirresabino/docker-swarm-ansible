# Ansible for Docker Swarm

This project provides Ansible playbooks to automate the configuration of a Docker Swarm cluster.

## Getting Started

This guide provides instructions on how to set up the development environment and run the Ansible playbooks to configure a Docker Swarm cluster.

### Prerequisites

- Docker
- Docker Compose
- Make (GNU Make)

### Quick Start with Makefile

The project includes a simplified Makefile that centralizes essential development operations:

```bash
# Complete setup and start development
make setup
make dev
```

This will:
1. Set up the complete development environment
2. Start containers and open a shell for development

### Development Environment Setup

**All development operations use the Makefile.**

```bash
# Setup and start development environment
make setup

# Start development (containers + shell)
make dev

# Check status
make status

# Stop containers
make stop
```

## Running Playbooks

**All playbook execution uses the Makefile.**

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

### Complete Testing

The `test` target automatically manages the test environment and runs all necessary tests:

```bash
# Run complete test suite (automatically manages test environment)
make test

# Run linting only
make lint
```

The test command:
1. Sets up the dedicated test environment
2. Runs ansible-lint and yamllint
3. Validates playbook syntax
4. Tests all roles with Molecule
5. Cleans up test environment

## Development Workflows

### Daily Development

```bash
# Start development
make dev

# Run tests
make test

# Check deployment
make deploy-check
```

### Debugging

```bash
# Debug mode with verbose output
make debug

# Test host connectivity
make ping

# Check versions
make version
```

## Maintenance

```bash
# Clean containers and volumes
make clean

# Check container status
make status
```

## Available Makefile Commands

Run `make help` to see all available commands:

- **Environment**: setup, start, stop, status, clean
- **Development**: dev, shell, logs  
- **Testing**: test, lint
- **Deployment**: deploy, deploy-check, deploy-managers, deploy-workers
- **Debug & Utils**: debug, ping, version

### Common Command Examples

```bash
make help         # Show all available commands
make setup        # Setup development environment
make dev          # Start development (containers + shell)
make test         # Run complete test suite
make deploy-check # Test deployment (dry-run)
make clean        # Clean up environment
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
└── playbook.yml                 # Main orchestration playbook
```

## Key Features

- **🚀 Simplified Makefile**: Essential commands for core development operations
- **🐳 Containerized Development**: Complete Docker-based environment with Docker-in-Docker support  
- **🧪 Streamlined Testing**: Automated test environment management with comprehensive validation
- **📋 Role-based Architecture**: Modular Ansible roles for different node types
- **🔧 Quality Assurance**: Integrated linting with ansible-lint and yamllint
- **📚 Clear Documentation**: Simplified guides focused on essential workflows
