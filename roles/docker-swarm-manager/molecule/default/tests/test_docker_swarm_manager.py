"""Tests for the docker-swarm-manager role."""

import os
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('swarm_manager_instance')


def test_docker_is_installed(host):
    """Verify Docker CLI is installed."""
    cmd = host.run("which docker")
    assert cmd.rc == 0


def test_docker_command_available(host):
    """Verify Docker command is available."""
    cmd = host.run("docker --version")
    assert cmd.rc == 0
    assert "Docker version" in cmd.stdout


def test_docker_sdk_available(host):
    """Verify Docker SDK for Python is installed."""
    cmd = host.run("python3 -c 'import docker; print(docker.__version__)'")
    assert cmd.rc == 0


def test_docker_socket_accessible(host):
    """Verify Docker socket is accessible."""
    socket_file = host.file("/var/run/docker.sock")
    assert socket_file.exists


def test_docker_swarm_manager_status(host):
    """Verify node is part of Docker Swarm as manager."""
    cmd = host.run("docker info --format '{{.Swarm.LocalNodeState}}'")
    assert cmd.rc == 0
    assert cmd.stdout.strip() == 'active'


def test_docker_swarm_control_available(host):
    """Verify node has manager control plane access."""
    cmd = host.run("docker info --format '{{.Swarm.ControlAvailable}}'")
    assert cmd.rc == 0
    assert cmd.stdout.strip() == 'true'


def test_docker_node_list_access(host):
    """Verify manager can list swarm nodes."""
    cmd = host.run("docker node ls")
    assert cmd.rc == 0
    # Should see at least 1 node (headers + at least the current node)
    lines = cmd.stdout.strip().split('\n')
    # Header + at least 1 node
    assert len(lines) >= 2


def test_manager_role_in_swarm(host):
    """Verify node has manager role in swarm."""
    cmd = host.run("docker node ls --filter 'role=manager' --quiet | wc -l")
    assert cmd.rc == 0
    # Should have at least 1 manager (this node)
    manager_count = int(cmd.stdout.strip())
    assert manager_count >= 1


def test_swarm_node_availability(host):
    """Verify swarm node is active and available."""
    # Get current node ID
    cmd = host.run("docker info --format '{{.Swarm.NodeID}}'")
    assert cmd.rc == 0
    node_id = cmd.stdout.strip()
    
    # Check node status
    cmd = host.run(f"docker node inspect {node_id} --format '{{{{.Status.State}}}}'")
    assert cmd.rc == 0
    assert cmd.stdout.strip() == 'ready'
    
    # Check node availability
    cmd = host.run(f"docker node inspect {node_id} --format '{{{{.Spec.Availability}}}}'")
    assert cmd.rc == 0
    assert cmd.stdout.strip() == 'active'
