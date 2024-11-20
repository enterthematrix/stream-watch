# Use Jenkins LTS as base image
FROM jenkins/jenkins:lts

# Set root password to "root"
USER root
RUN echo "root:root" | chpasswd

# Create a symlink for python
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install necessary packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    pyenv \
    git \
    vim \
    net-tools \
    curl \
    tail \
    && apt-get clean

# Set the user back to Jenkins
USER jenkins

# Expose the default Jenkins port
EXPOSE 8080
