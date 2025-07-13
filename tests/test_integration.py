import pytest

def test_docker_installed(host):
    assert host.package("docker-ce").is_installed

def test_docker_service_running_and_enabled(host):
    service = host.service("docker")
    assert service.is_running
    assert service.is_enabled

def test_systemd_timesyncd_running_and_enabled(host):
    service = host.service("systemd-timesyncd")
    assert service.is_running
    assert service.is_enabled

def test_ntp_configured(host):
    timesyncd_conf = host.file("/etc/systemd/timesyncd.conf")
    assert timesyncd_conf.contains("NTP=")

def test_system_clock_synchronized(host):
    command = host.run("timedatectl status")
    assert "System clock synchronized: yes" in command.stdout
