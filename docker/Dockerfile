# Use Jenkins LTS as the base image
FROM jenkins/jenkins:lts

# Switch to root user to install packages
USER root

# Update the package manager and install required packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    vim \
    net-tools \
    iputils-ping \
    curl \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Verify installations
RUN python3 --version && git --version && vim --version && netstat --version

# Switch back to Jenkins user for security
USER jenkins