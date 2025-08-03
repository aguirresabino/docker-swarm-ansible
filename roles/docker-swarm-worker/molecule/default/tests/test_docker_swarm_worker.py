"""Tests for the docker-swarm-worker role."""

import os
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('workers')


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


def test_docker_swarm_is_active(host):
    """Verify swarm is active on worker node."""
    cmd = host.run("docker info --format '{{.Swarm.LocalNodeState}}'")
    assert cmd.rc == 0
    assert cmd.stdout.strip() == 'active'


def test_docker_swarm_can_access_docker_info(host):
    """Verify worker can access Docker swarm information."""
    cmd = host.run("docker info")
    assert cmd.rc == 0
    assert "Swarm:" in cmd.stdout


def test_docker_worker_can_run_containers(host):
    """Verify worker node can run containers."""
    # Test running a simple container
    cmd = host.run("docker run --rm hello-world")
    assert cmd.rc == 0
    assert "Hello from Docker!" in cmd.stdout


def test_swarm_cluster_has_multiple_nodes(host):
    """Verify swarm cluster has multiple nodes."""
    cmd = host.run("docker node ls --format '{{.Hostname}}'")
    assert cmd.rc == 0
    hostnames = cmd.stdout.strip().split('\n')
    # Should have at least 3 nodes (1 manager + 2 workers)
    assert len(hostnames) >= 3


def test_worker_node_configuration(host):
    """Verify worker node has proper configuration."""
    # In shared Docker socket scenarios, validate configuration exists
    cmd = host.run("docker info --format '{{json .}}'")
    assert cmd.rc == 0
    # Verify swarm is active and accessible
    assert '"LocalNodeState":"active"' in cmd.stdout
