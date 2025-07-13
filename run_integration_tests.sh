#!/bin/bash

set -e

CONTAINER_NAME="ansible_integration_test_host"
IMAGE_NAME="ansible_integration_test_image"

# Build the Docker image for the test host
docker build -t ${IMAGE_NAME} -f Dockerfile.test .

# Run the test host container
docker run -d --privileged --name ${CONTAINER_NAME} ${IMAGE_NAME}

# Copy Ansible project to the container
docker cp . ${CONTAINER_NAME}:/ansible

# Run the playbook inside the container
docker exec ${CONTAINER_NAME} bash -c "cd /ansible && ansible-playbook -i inventory/hosts.ini playbook.yml"

# Run Testinfra tests against the container
docker exec ${CONTAINER_NAME} bash -c "pip install -r /ansible/tests/requirements.txt && pytest /ansible/tests/test_integration.py --hosts=docker://${CONTAINER_NAME}"

# Clean up
docker stop ${CONTAINER_NAME}
docker rm ${CONTAINER_NAME}

echo "Integration tests completed."
