def test_docker_installed(host):
    docker_package = host.package("docker-ce")
    assert docker_package.is_installed

def test_docker_service_running_and_enabled(host):
    docker_service = host.service("docker")
    assert docker_service.is_running
    assert docker_service.is_enabled

def test_user_in_docker_group(host):
    user = host.user("{{ ansible_user }}")
    assert "docker" in user.groups

def test_systemd_timesyncd_running_and_enabled(host):
    timesyncd_service = host.service("systemd-timesyncd")
    assert timesyncd_service.is_running
    assert timesyncd_service.is_enabled

def test_ntp_configured(host):
    timesyncd_conf = host.file("/etc/systemd/timesyncd.conf")
    assert timesyncd_conf.contains("NTP={{ common_ntp_server }}")

def test_system_clock_synchronized(host):
    command = host.run("timedatectl status")
    assert "System clock synchronized: yes" in command.stdout

def test_docker_registry_login(host):
    if host.ansible.get_variables().get("docker_registry_username") and \
       host.ansible.get_variables().get("docker_registry_password"):
        command = host.run("docker info")
        username = host.ansible.get_variables().get("docker_registry_username")
        assert f"Username: {username}" in command.stdout

