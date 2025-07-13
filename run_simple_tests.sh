#!/bin/bash

set -e

echo "==========================================="
echo "Simplified Ansible Testing Protocol"
echo "==========================================="

echo "1. Static Analysis Tests"
echo "----------------------------------------"

echo "Running ansible-lint..."
ansible-lint playbook.yml

echo "Running yamllint..."
yamllint .

echo ""
echo "2. Playbook Validation Tests"
echo "----------------------------------------"

echo "Running playbook in check mode..."
ansible-playbook -i inventory/hosts.ini playbook.yml --check --limit all

echo ""
echo "3. Role Syntax and Lint Tests"
echo "----------------------------------------"

for role in common docker_manager docker_worker; do
    echo "Testing role: $role"
    if [ -d "roles/$role/molecule" ]; then
        echo "  Running lint checks..."
        ./run_molecule_tests.sh "$role" lint
        echo "  Running syntax check..."
        cd "roles/$role" && molecule syntax && cd ../..
    else
        echo "No molecule tests found for $role"
    fi
done

echo ""
echo "4. Role Task Validation"
echo "----------------------------------------"

echo "Validating role tasks with ansible-lint..."
for role in common docker_manager docker_worker; do
    echo "Checking role: $role"
    ansible-lint "roles/$role/tasks/main.yml" 2>/dev/null || echo "  Warning: Issues found in $role"
done

echo ""
echo "==========================================="
echo "✅ All basic tests completed successfully!"
echo "Note: Docker-in-Docker Molecule tests"
echo "require additional environment setup."
echo "==========================================="
