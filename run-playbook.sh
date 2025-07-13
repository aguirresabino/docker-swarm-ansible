#!/bin/bash
set -e
TARGET=$1
EXTRA_ARGS=""
[ "$2" == "--check" ] && EXTRA_ARGS="--check"
CMD="ansible-playbook -i inventory/hosts.ini playbook.yml --vault-password-file .vault_pass $EXTRA_ARGS"

case "$TARGET" in
    all|managers|workers)
        docker compose exec ansible-control $CMD --limit "$TARGET"
        ;;
    *)
        echo "Usage: $0 {all|managers|workers} [--check]" >&2; exit 1
        ;;
esac