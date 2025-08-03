"""Tests for the docker-swarm-worker role."""

import os
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('workers')


def test_python_is_installed(host):
    """Verify Python is installed."""
    cmd = host.run("which python3")
    assert cmd.rc == 0


def test_docker_sdk_available(host):
    """Verify Docker SDK for Python is installed."""
    cmd = host.run("python3 -c 'import docker; print(docker.__version__)'")
    assert cmd.rc == 0


def test_docker_socket_accessible(host):
    """Verify Docker socket is accessible."""
    socket_file = host.file("/var/run/docker.sock")
    assert socket_file.exists


def test_ansible_requirements_installed(host):
    """Verify required packages are installed."""
    packages = ['python3-pip', 'python3-docker', 'ca-certificates', 'curl']
    for package in packages:
        pkg = host.package(package)
        assert pkg.is_installed
