# Dockerfile for Ansible Development and Testing

FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Add Docker's official GPG key and set up the repository
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker CLI for Docker-in-Docker
RUN apt-get update && apt-get install -y --no-install-recommends docker-ce-cli && rm -rf /var/lib/apt/lists/*

# Install Python dependencies for Ansible, Molecule, and testing
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
    ansible \
    docker \
    molecule \
    molecule-docker \
    testinfra \
    ansible-lint \
    yamllint \
    pytest \
    pytest-testinfra

# Configure the working directory
WORKDIR /ansible
COPY . /ansible

# Default command
CMD ["ansible", "--version"]