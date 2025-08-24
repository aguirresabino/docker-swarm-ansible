# Docker Swarm with Ansible

This project automates the configuration of a Docker Swarm cluster using Ansible. It implements a multi-tier Docker Swarm cluster with a **Primary Manager Node** that initializes the swarm, **Additional Manager Nodes** that join as managers for high availability, and **Worker Nodes** that join the cluster as workers.

It also features a containerized development environment and automated testing with Molecule.

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
│   │   └── all/
│   │       └── vars.yml          # Shared cluster configuration
│   └── hosts.ini                 # Host definitions
├── roles/
│   ├── ntp/                   # Base configuration for all nodes
│   │   ├── defaults/
│   │   ├── molecule/             # Automated tests
│   │   └── tasks/
│   ├── docker/                   # Docker installation and configuration
│   │   ├── defaults/
│   │   ├── molecule/             # Automated tests
│   │   └── tasks/
│   ├── docker-swarm-init/        # Docker Swarm primary manager initialization
│   │   ├── defaults/
│   │   ├── molecule/             # Automated tests
│   │   └── tasks/
│   ├── docker-swarm-manager/     # Additional Docker Swarm managers
│   │   ├── defaults/
│   │   ├── molecule/             # Automated tests
│   │   └── tasks/
│   ├── docker-swarm-worker/      # Docker Swarm worker nodes
│   │   ├── defaults/
│   │   ├── molecule/             # Automated tests
│   │   └── tasks/
├── ssh_keys/                     # SSH keys for authentication
├── Makefile                      # Automation commands
├── compose.yml                   # Docker Compose for development
├── Dockerfile                    # Development container
└── playbook.yml                 # Main playbook
```

- **ntp**: Basic system configuration (NTP, users, etc.) applied to all nodes.
- **docker**: Docker installation and configuration for all nodes.
- **docker-swarm-init**: Docker Swarm initialization for the primary manager node.
- **docker-swarm-manager**: Joins additional nodes as managers to the existing swarm cluster.
- **docker-swarm-worker**: Joins worker nodes to the existing swarm cluster.

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

### Other Commands

```bash
# Development with shell access
make dev

# View container logs
make logs

# Test connectivity
make ping

# Debug mode
make debug

# Show versions
make version
```

## CI/CD Pipeline

This project includes automated testing via GitHub Actions. The CI pipeline runs on every pull request and:

- **Linting**: Validates YAML syntax and Ansible best practices
- **Testing**: Runs all Molecule tests for each role
- **Quality Gates**: Ensures code quality before merge

### Pipeline Status

The CI workflow automatically:
1. Sets up the containerized environment
2. Runs `make lint` to check code quality
3. Runs `make test` to execute all tests
4. Reports results as PR status checks

All tests must pass before code can be merged to the main branch.

## Adding Manager Nodes

To add additional manager nodes for high availability:

1. **Add managers to inventory**: Edit `inventory/hosts.ini` and add new hosts to the `[managers]` group:

```ini
[primary_manager]
odin ansible_host=192.168.1.65 ansible_ssh_private_key_file=/ansible/ssh_keys/odin ansible_port=2201

[additional_managers]
manager2 ansible_host=192.168.1.68 ansible_ssh_private_key_file=/ansible/ssh_keys/manager2 ansible_port=2201
manager3 ansible_host=192.168.1.69 ansible_ssh_private_key_file=/ansible/ssh_keys/manager3 ansible_port=2201

[managers:children]
primary_manager
additional_managers
```

2. **Add SSH keys**: Place the SSH private keys in the `ssh_keys/` directory with appropriate permissions (600).

3. **Deploy**: Run the deployment which will automatically:
   - Apply common configuration and Docker installation to new managers
   - Initialize swarm on primary manager
   - Join additional managers using the `docker-swarm-manager` role

```bash
make deploy
```

The playbook automatically detects when there are multiple managers and applies the `docker-swarm-manager` role to join them to the existing cluster.

## Adding Worker Nodes

To add worker nodes to the Docker Swarm cluster:

1. **Add workers to inventory**: Edit `inventory/hosts.ini` and add new hosts to the `[workers]` group:

```ini
[workers]
thor ansible_host=192.168.1.66 ansible_ssh_private_key_file=/ansible/ssh_keys/thor ansible_port=2201
loki ansible_host=192.168.1.67 ansible_ssh_private_key_file=/ansible/ssh_keys/loki ansible_port=2201
worker3 ansible_host=192.168.1.70 ansible_ssh_private_key_file=/ansible/ssh_keys/worker3 ansible_port=2201
```

2. **Add SSH keys**: Place the SSH private keys in the `ssh_keys/` directory with appropriate permissions (600).

3. **Deploy**: Run the deployment which will automatically:
   - Apply common configuration and Docker installation to new workers
   - Initialize swarm on primary manager if not already done
   - Join worker nodes using the `docker-swarm-worker` role

```bash
make deploy
```

The playbook automatically applies the `docker-swarm-worker` role to all nodes in the `[workers]` group to join them to the existing cluster as worker nodes.
