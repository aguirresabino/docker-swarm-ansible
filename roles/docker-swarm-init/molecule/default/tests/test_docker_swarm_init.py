"""Tests for the docker-swarm-init role."""

import os
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('all')


def test_docker_is_available(host):
    """Verify Docker command is available."""
    cmd = host.run("docker --version")
    assert cmd.rc == 0


def test_docker_sdk_available(host):
    """Verify Docker SDK for Python is installed."""
    cmd = host.run("python3 -c 'import docker; print(docker.__version__)'")
    assert cmd.rc == 0


def test_docker_socket_accessible(host):
    """Verify Docker socket is accessible."""
    socket_file = host.file("/var/run/docker.sock")
    assert socket_file.exists


def test_swarm_initialization_requirements(host):
    """Verify requirements for swarm initialization are met."""
    # Test that Docker info command works
    cmd = host.run("docker info")
    assert cmd.rc == 0
