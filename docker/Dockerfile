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

# Ensure Jenkins user home directory exists
RUN mkdir -p /home/jenkins && chown -R jenkins:jenkins /home/jenkins

# Add pyenv initialization to Jenkins' .bashrc and .profile to make sure it's sourced
RUN echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> /home/jenkins/.bashrc
RUN echo 'eval "$(pyenv init --path)"' >> /home/jenkins/.bashrc
RUN echo 'eval "$(pyenv init -)"' >> /home/jenkins/.bashrc
RUN echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> /home/jenkins/.profile
RUN echo 'eval "$(pyenv init --path)"' >> /home/jenkins/.profile
RUN echo 'eval "$(pyenv init -)"' >> /home/jenkins/.profile

# Install pyenv properly for Jenkins user using bash -l -c
RUN su - jenkins -c 'bash -l -c "pyenv install 3.10.4"'
RUN su - jenkins -c 'bash -l -c "pyenv global 3.10.4"'

# Create symlink for python to point to python3
RUN ln -s /usr/bin/python3 /usr/bin/python

# Set the user back to Jenkins
USER jenkins

# Expose Jenkins default port
EXPOSE 8080
