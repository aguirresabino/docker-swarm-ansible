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

This project uses Molecule for testing Ansible roles. To run the tests for a specific role, use the following command from within the `ansible-control` container:

```bash
docker compose exec ansible-control bash -c "cd roles/<role_name> && molecule test"
```

For example, to run tests for the `common` role:

```bash
docker compose exec ansible-control bash -c "cd roles/common && molecule test"
```

## Project Structure

```
.
├── docs/
├── inventory/
│   ├── group_vars/
│   │   └── all.yml
│   └── hosts.ini
├── roles/
│   ├── common/
│   ├── docker_manager/
│   └── docker_worker/
├── tests/
├── compose.yml
├── Dockerfile
├── run-playbook.sh
└── playbook.yml
```
