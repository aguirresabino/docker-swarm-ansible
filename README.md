# Ansible for Docker Swarm

This project provides Ansible playbooks to automate the configuration of a Docker Swarm cluster.

## Getting Started

This guide provides instructions on how to set up the development environment and run the Ansible playbooks to configure a Docker Swarm cluster.

### Prerequisites

- Docker
- Docker Compose

### Development Environment Setup

1.  **Build and start the containerized development environment:**

    ```bash
    docker compose up --build -d
    ```

2.  **Access the control node container:**

    ```bash
    docker compose exec ansible-control bash
    ```

3.  **Shut down the environment when you are finished:**

    ```bash
    docker compose down
    ```

### Running the Playbooks

The `run-playbook.sh` script is the recommended way to execute the playbooks.

-   **Run on all hosts:**

    ```bash
    ./run-playbook.sh all
    ```

-   **Run in check mode (dry-run) on managers only:**

    ```bash
    ./run-playbook.sh managers --check
    ```

-   **Run on workers only:**

    ```bash
    ./run-playbook.sh workers
    ```

## Running Tests

This project uses a comprehensive testing strategy with multiple levels of validation. All tests run within containerized environments using **Python 3.11** and **ansible-lint 25.6.1** for enhanced compatibility and features.

### Quick Testing

For rapid development validation, use the simplified test script:

```bash
# Start the development environment
docker compose up --build -d

# Run simplified tests (recommended for development)
./run_simple_tests.sh
```

This script performs:
- Static analysis (ansible-lint, yamllint)
- Playbook validation in check mode
- Role syntax validation with Molecule
- Task validation

### Development Environment Testing

The development environment is configured to support Docker-in-Docker for running Molecule tests:

```bash
# Start the development environment
docker compose up --build -d

# Access the control node container
docker compose exec ansible-control bash

# Start the testing environment (alternative)
docker compose --profile testing up --build -d
docker compose exec ansible-test bash
```

### Role-Specific Testing with Molecule

Each role has its own Molecule test suite. Note: Docker-in-Docker functionality for full Molecule tests requires additional configuration in some environments.

```bash
# Using the helper script (basic syntax testing)
./run_molecule_tests.sh <role_name> syntax

# Examples:
./run_molecule_tests.sh common lint
./run_molecule_tests.sh common syntax
./run_molecule_tests.sh docker_manager lint
./run_molecule_tests.sh docker_worker syntax

# Available test commands:
# - syntax: Test playbook syntax (recommended)
# - lint: Run ansible-lint and yamllint on role (custom implementation for Molecule 6.x)
# - converge: Run the role (requires Docker-in-Docker)
# - verify: Run tests (requires Docker-in-Docker)
# - destroy: Destroy test instances
# - list: List test instances

**Note**: The lint functionality is implemented as a custom solution because Molecule 6.x removed the integrated `molecule lint` command. Our implementation combines ansible-lint and yamllint for comprehensive code quality checking.
```

#### Manual Molecule Testing

For manual testing from within the container:

```bash
# From within ansible-control container
cd roles/common && molecule syntax
cd roles/docker_manager && molecule syntax
cd roles/docker_worker && molecule syntax

# For full testing (may require additional Docker-in-Docker setup)
cd roles/common && molecule test
```

### Role Test Structure

Each role follows this standardized Molecule test structure:

```
roles/<role_name>/
├── molecule/
│   └── default/
│       ├── molecule.yml      # Molecule configuration
│       ├── converge.yml      # Playbook to test the role
│       ├── prepare.yml       # System preparation
│       └── tests/
│           └── test_<role>.py # Testinfra test cases
```

### Testing Features

- **Docker Driver**: All tests use Docker containers for isolation
- **Privileged Containers**: Support for systemd and Docker-in-Docker
- **Parallel Testing**: Tests run in parallel using pytest-xdist
- **Comprehensive Coverage**: Tests include lint, syntax, converge, idempotence, and verification
- **Multi-Node Testing**: Worker role tests include both manager and worker nodes

## Running Integration Tests

To run the comprehensive integration tests that verify the entire playbook execution across multiple test scenarios, use the `run_integration_tests.sh` script:

```bash
./run_integration_tests.sh
```

This script will:
1. Build a test Docker image (`Dockerfile.test`)
2. Start a test container with proper privileges
3. Copy the Ansible project into the container
4. Install test dependencies
5. Run Ansible lint checks
6. Execute the main `playbook.yml` in check mode (dry-run)
7. Run the main `playbook.yml` against the test container
8. Execute Testinfra integration tests (`tests/test_integration.py`)
9. Run Molecule tests for all roles
10. Clean up test containers

### Integration Test Structure

The integration tests validate:
- **Static Analysis**: `ansible-lint` for playbook quality
- **Dry-run Validation**: Playbook execution in check mode
- **Full Deployment**: Complete playbook execution
- **Infrastructure Validation**: Testinfra tests for deployed services
- **Role Testing**: Individual Molecule tests for each role

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
│   │   ├── tasks/
│   │   └── tests/
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
├── compose.yml                   # Docker Compose configuration
├── Dockerfile                    # Multi-stage container build
├── Dockerfile.test              # Test host container
├── run-playbook.sh              # Playbook execution script
├── run_integration_tests.sh     # Integration test runner
├── run_molecule_tests.sh        # Individual role test runner
└── playbook.yml                 # Main orchestration playbook
```
