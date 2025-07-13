def test_docker_installed_on_workers(host):
    """Test that Docker is installed on worker nodes."""
    if 'workers' in host.backend.get_hostname() or 'worker' in host.backend.get_hostname():
        docker_package = host.package("docker-ce")
        assert docker_package.is_installed


def test_docker_service_running_and_enabled_on_workers(host):
    """Test that Docker service is running and enabled on worker nodes."""
    if 'workers' in host.backend.get_hostname() or 'worker' in host.backend.get_hostname():
        docker_service = host.service("docker")
        assert docker_service.is_running
        assert docker_service.is_enabled


def test_docker_swarm_mode_enabled_on_workers(host):
    """Test that Docker Swarm mode is enabled on worker nodes."""
    if 'workers' in host.backend.get_hostname() or 'worker' in host.backend.get_hostname():
        command = host.run("docker info --format '{{.Swarm.LocalNodeState}}'")
        assert command.rc == 0
        assert "active" in command.stdout


def test_docker_swarm_worker_role(host):
    """Test that worker nodes cannot list cluster nodes (manager-only command)."""
    if 'workers' in host.backend.get_hostname() or 'worker' in host.backend.get_hostname():
        command = host.run("docker node ls")
        # Workers should not be able to run manager commands
        assert command.rc != 0


def test_docker_swarm_node_status_on_workers(host):
    """Test that worker nodes are part of the swarm."""
    if 'workers' in host.backend.get_hostname() or 'worker' in host.backend.get_hostname():
        command = host.run("docker info --format '{{.Swarm.NodeID}}'")
        assert command.rc == 0
        # Should have a node ID if part of swarm
        assert len(command.stdout.strip()) > 0


def test_systemd_timesyncd_running_and_enabled_on_workers(host):
    """Test that systemd-timesyncd service is running and enabled on worker nodes."""
    if 'workers' in host.backend.get_hostname() or 'worker' in host.backend.get_hostname():
        timesyncd_service = host.service("systemd-timesyncd")
        assert timesyncd_service.is_running
        assert timesyncd_service.is_enabled


def test_docker_installed_on_managers(host):
    """Test that Docker is installed on manager nodes."""
    if 'managers' in host.backend.get_hostname() or 'manager' in host.backend.get_hostname():
        docker_package = host.package("docker-ce")
        assert docker_package.is_installed


def test_docker_swarm_manager_can_list_nodes(host):
    """Test that manager nodes can list cluster nodes."""
    if 'managers' in host.backend.get_hostname() or 'manager' in host.backend.get_hostname():
        command = host.run("docker node ls")
        assert command.rc == 0
