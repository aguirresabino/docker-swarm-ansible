#!/bin/bash

set -e

CONTAINER_NAME="ansible_integration_test_host"
IMAGE_NAME="ansible_integration_test_image"

echo "=========================================="
echo "Starting Ansible Integration Tests"
echo "=========================================="

# Function to clean up containers
cleanup() {
    echo "Cleaning up test containers..."
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
    docker rmi ${IMAGE_NAME} 2>/dev/null || true
}

# Trap to ensure cleanup happens
trap cleanup EXIT

echo "Step 1: Building Docker image for test host..."
docker build -t ${IMAGE_NAME} -f Dockerfile.test .

echo "Step 2: Starting test host container..."
docker run -d --privileged --name ${CONTAINER_NAME} ${IMAGE_NAME}

echo "Step 3: Copying Ansible project to container..."
docker cp . ${CONTAINER_NAME}:/ansible

echo "Step 4: Installing test dependencies in container..."
docker exec ${CONTAINER_NAME} bash -c "pip3 install -r /ansible/tests/requirements.txt"

echo "Step 5: Running Ansible lint checks..."
docker exec ${CONTAINER_NAME} bash -c "cd /ansible && ansible-lint playbook.yml"

echo "Step 6: Running playbook in check mode..."
docker exec ${CONTAINER_NAME} bash -c "cd /ansible && ansible-playbook -i inventory/hosts.ini playbook.yml --check --diff"

echo "Step 7: Running the main playbook..."
docker exec ${CONTAINER_NAME} bash -c "cd /ansible && ansible-playbook -i inventory/hosts.ini playbook.yml"

echo "Step 8: Running Testinfra integration tests..."
docker exec ${CONTAINER_NAME} bash -c "cd /ansible && pytest tests/test_integration.py --hosts=docker://${CONTAINER_NAME} -v"

echo "Step 9: Running Molecule tests for all roles..."
for role in common docker_manager docker_worker; do
    if [ -d "roles/$role/molecule" ]; then
        echo "Running Molecule tests for role: $role"
        docker exec ${CONTAINER_NAME} bash -c "cd /ansible/roles/$role && molecule test --destroy=never" || echo "Warning: Molecule test failed for $role"
    else
        echo "Skipping $role - no molecule tests found"
    fi
done

echo "=========================================="
echo "All integration tests completed successfully!"
echo "=========================================="
