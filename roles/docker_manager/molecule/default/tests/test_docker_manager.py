def test_docker_installed(host):
    """Test that Docker is installed."""
    docker_package = host.package("docker-ce")
    assert docker_package.is_installed


def test_docker_service_running_and_enabled(host):
    """Test that Docker service is running and enabled."""
    docker_service = host.service("docker")
    assert docker_service.is_running
    assert docker_service.is_enabled


def test_docker_swarm_mode_enabled(host):
    """Test that Docker Swarm mode is enabled."""
    command = host.run("docker info --format '{{.Swarm.LocalNodeState}}'")
    assert command.rc == 0
    assert "active" in command.stdout


def test_docker_swarm_manager_role(host):
    """Test that the node is a Swarm manager."""
    command = host.run("docker node ls")
    assert command.rc == 0
    # Should be able to list nodes if it's a manager


def test_docker_swarm_manager_status(host):
    """Test that the manager node shows as Leader or Reachable."""
    command = host.run("docker node ls --format '{{.ManagerStatus}}'")
    assert command.rc == 0
    # Should show Leader or Reachable for manager nodes
    assert any(status in command.stdout for status in ["Leader", "Reachable"])


def test_docker_swarm_ports_listening(host):
    """Test that Docker Swarm management ports are listening."""
    # Docker Swarm management port
    assert host.socket("tcp://0.0.0.0:2377").is_listening


def test_systemd_timesyncd_running_and_enabled(host):
    """Test that systemd-timesyncd service is running and enabled."""
    timesyncd_service = host.service("systemd-timesyncd")
    assert timesyncd_service.is_running
    assert timesyncd_service.is_enabled
