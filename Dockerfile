FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install ansible docker "molecule[docker]" testinfra ansible-lint

# Configure the working directory
WORKDIR /ansible
COPY . /ansible

# Default command
CMD ["ansible", "--version"]