# Docker Swarm with Ansible

This project automates the configuration of a Docker Swarm cluster using Ansible. The project includes roles to configure manager and worker nodes, with a containerized development environment and automated testing.

## Tools Used

- **Ansible**: Configuration automation and deployment
- **Docker**: Containerization and Docker Swarm
- **Molecule**: Testing framework for Ansible roles
- **Python**: Base language for Ansible and testing
- **Make**: Development task automation

## Project Structure

```
.
├── inventory/
│   ├── group_vars/               # Global variables
│   └── hosts.ini                 # Host definitions
├── roles/
│   ├── common/                   # Base configuration for all nodes
│   │   ├── defaults/
│   │   ├── molecule/             # Automated tests
│   │   └── tasks/
├── ssh_keys/                     # SSH keys for authentication
├── Makefile                      # Automation commands
├── compose.yml                   # Docker Compose for development
├── Dockerfile                    # Development container
└── playbook.yml                 # Main playbook
```

## Getting Started

### Prerequisites

- Docker
- Docker Compose
- Make (GNU Make)

### Starting Local Environment

```bash
# Setup and start development environment
make setup

# Access container shell
make shell

# Check container status
make status
```

### Destroying Environment

```bash
# Stop containers
make stop

# Clean completely (containers, volumes, unused images)
make clean
```

### Running Tests

```bash
# Run all tests (lint + molecule)
make test

# Run only linting
make lint
```

### Deployment

```bash
# Deploy to all hosts
make deploy

# Test deployment (dry-run)
make deploy-check

# Deploy only to managers
make deploy-managers

# Deploy only to workers
make deploy-workers
```
