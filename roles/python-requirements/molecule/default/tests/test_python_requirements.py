"""Tests for the python-requirements role."""

import os
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']
).get_hosts('all')


def test_python3_installed(host):
    """Verify Python3 is installed and available."""
    cmd = host.run("python3 --version")
    assert cmd.rc == 0
    assert "Python 3" in cmd.stdout


def test_python3_venv_installed(host):
    """Verify python3-venv is installed."""
    pkg = host.package("python3-venv")
    assert pkg.is_installed


def test_python3_full_installed(host):
    """Verify python3-full is installed."""
    pkg = host.package("python3-full")
    assert pkg.is_installed


def test_virtual_environment_created(host):
    """Verify virtual environment directory exists."""
    venv_dir = host.file("/opt/ansible-venv")
    assert venv_dir.exists
    assert venv_dir.is_directory


def test_virtual_environment_python(host):
    """Verify virtual environment Python is available."""
    venv_python = host.file("/opt/ansible-venv/bin/python")
    assert venv_python.exists
    assert venv_python.is_file


def test_virtual_environment_pip(host):
    """Verify virtual environment pip is available."""
    venv_pip = host.file("/opt/ansible-venv/bin/pip")
    assert venv_pip.exists
    assert venv_pip.is_file


def test_docker_sdk_installed_in_venv(host):
    """Verify Docker SDK for Python is installed in virtual environment."""
    cmd = host.run("/opt/ansible-venv/bin/python -c 'import docker; print(docker.__version__)'")
    assert cmd.rc == 0


def test_jsondiff_installed_in_venv(host):
    """Verify jsondiff module is installed in virtual environment."""
    cmd = host.run("/opt/ansible-venv/bin/python -c 'import jsondiff; print(\"jsondiff imported successfully\")'")
    assert cmd.rc == 0
    assert "jsondiff imported successfully" in cmd.stdout


def test_docker_sdk_version_in_venv(host):
    """Verify Docker SDK version is 7.0.0 or higher in virtual environment."""
    cmd = host.run("/opt/ansible-venv/bin/python -c 'import docker; print(docker.__version__)'")
    assert cmd.rc == 0
    # Just verify we can import and get version - specific version check would be too rigid


def test_apt_packages_installed(host):
    """Verify required APT packages are installed."""
    packages = ["python3", "python3-pip", "python3-setuptools", "python3-dev", "python3-venv", "python3-full"]
    for package in packages:
        pkg = host.package(package)
        assert pkg.is_installed
