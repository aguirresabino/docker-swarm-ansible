# Multi-stage build for development and testing

# Base stage with common dependencies
# Using Python 3.11 for compatibility with ansible-lint 25.6.1+
FROM python:3.11-slim as base

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI for Docker-in-Docker support
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
# First upgrade pip to latest version
RUN pip install --upgrade pip \
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

# Development stage
FROM base as development

# Configure the working directory
WORKDIR /ansible
COPY . /ansible

# Default command
CMD ["ansible", "--version"]

# Testing stage with additional test dependencies
FROM base as testing

# Install additional testing tools
RUN pip install --no-cache-dir \
    pytest-xdist \
    pytest-cov \
    pytest-html

# Configure the working directory
WORKDIR /ansible
COPY . /ansible

# Default command for testing
CMD ["molecule", "--version"]