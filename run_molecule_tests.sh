#!/bin/bash

set -e

# Script to run Molecule tests for individual roles
# Usage: ./run_molecule_tests.sh [role_name] [test_command]

ROLE_NAME=$1
TEST_COMMAND=${2:-"test"}

if [ -z "$ROLE_NAME" ]; then
    echo "Usage: $0 <role_name> [test_command]"
    echo "Available roles:"
    ls -1 roles/ | grep -v "README" || true
    echo ""
    echo "Available test commands:"
    echo "  test        - Run full test suite (default)"
    echo "  converge    - Run converge only"
    echo "  verify      - Run verify only"
    echo "  lint        - Run lint only"
    echo "  destroy     - Destroy test instances"
    echo "  list        - List test instances"
    exit 1
fi

ROLE_PATH="roles/$ROLE_NAME"

if [ ! -d "$ROLE_PATH" ]; then
    echo "Error: Role '$ROLE_NAME' not found in roles/ directory"
    exit 1
fi

if [ ! -d "$ROLE_PATH/molecule" ]; then
    echo "Error: Role '$ROLE_NAME' does not have molecule tests configured"
    echo "Expected directory: $ROLE_PATH/molecule"
    exit 1
fi

echo "Running Molecule $TEST_COMMAND for role: $ROLE_NAME"
echo "Role path: $ROLE_PATH"
echo "----------------------------------------"

# Special handling for lint since Molecule 6.x doesn't have lint command
if [ "$TEST_COMMAND" = "lint" ]; then
    echo "Running lint checks for role $ROLE_NAME..."
    
    # Check if running inside Docker container
    if [ -f /.dockerenv ]; then
        echo "Running inside Docker container..."
        cd "$ROLE_PATH" 
        echo "Running ansible-lint..."
        ansible-lint . || echo "Lint issues found in $ROLE_NAME"
        echo "Running yamllint..."
        yamllint . || echo "YAML lint issues found in $ROLE_NAME"
    else
        echo "Running via Docker Compose..."
        docker compose exec ansible-control bash -c "cd $ROLE_PATH && ansible-lint . && yamllint ."
    fi
else
    # Check if running inside Docker container
    if [ -f /.dockerenv ]; then
        echo "Running inside Docker container..."
        cd "$ROLE_PATH" && molecule "$TEST_COMMAND"
    else
        echo "Running via Docker Compose..."
        docker compose exec ansible-control bash -c "cd $ROLE_PATH && molecule $TEST_COMMAND"
    fi
fi

echo "----------------------------------------"
echo "Molecule $TEST_COMMAND completed for role: $ROLE_NAME"
