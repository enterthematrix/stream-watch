# Use Jenkins LTS as the base image
FROM jenkins/jenkins:lts

# Set root password to "root"
USER root
RUN echo "root:root" | chpasswd

# Add Jenkins user to the sudo group
RUN usermod -aG sudo jenkins

# Install commonly used Linux utilities and required packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    git \
    vim \
    net-tools \
    curl \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    sudo \
    && apt-get clean

# Install pyenv and set up Python for Jenkins user
RUN curl https://pyenv.run | bash
ENV PATH="/root/.pyenv/bin:${PATH}"
RUN pyenv init --path

# Allow Jenkins user to use pyenv by setting up environment variables
RUN echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> /etc/profile.d/pyenv.sh
RUN echo 'eval "$(pyenv init --path)"' >> /etc/profile.d/pyenv.sh
RUN echo 'eval "$(pyenv init -)"' >> /etc/profile.d/pyenv.sh

# Install a specific Python version using pyenv
RUN pyenv install 3.10.4
RUN pyenv global 3.10.4

# Create symlink for python to point to python3
RUN ln -s /usr/bin/python3 /usr/bin/python

# Set the user back to Jenkins
USER jenkins

# Expose Jenkins default port
EXPOSE 8080
