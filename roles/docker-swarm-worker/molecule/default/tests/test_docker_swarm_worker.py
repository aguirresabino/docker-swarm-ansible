"""Tests for the docker-swarm-worker role."""

import os
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('swarm_worker_instance')


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


def test_docker_swarm_worker_status(host):
    """Verify node is part of Docker Swarm as worker."""
    cmd = host.run("docker info --format '{{.Swarm.LocalNodeState}}'")
    assert cmd.rc == 0
    assert cmd.stdout.strip() == 'active'


def test_docker_swarm_cluster_participation(host):
    """Verify worker can see basic swarm information."""
    cmd = host.run("docker info --format '{{.Swarm.NodeID}}'")
    assert cmd.rc == 0
    # NodeID should be a non-empty string for active swarm member
    assert len(cmd.stdout.strip()) > 0


def test_docker_worker_can_run_containers(host):
    """Verify worker node can run containers."""
    # Test running a simple container
    cmd = host.run("docker run --rm hello-world")
    assert cmd.rc == 0
    assert "Hello from Docker!" in cmd.stdout


def test_docker_swarm_cluster_info(host):
    """Verify worker node has correct swarm cluster information."""
    cmd = host.run("docker info --format '{{.Swarm.Cluster.ID}}'")
    assert cmd.rc == 0
    # Cluster ID should be a non-empty string
    assert len(cmd.stdout.strip()) > 0


def test_docker_swarm_is_active(host):
    """Verify this node is active in the swarm cluster."""
    cmd = host.run("docker info --format '{{.Swarm.LocalNodeState}}'")
    assert cmd.rc == 0
    assert cmd.stdout.strip() == 'active'
