# Start with a base image with Java (required for Jenkins)
FROM openjdk:11-jdk

# Set environment variables for Jenkins
ENV JENKINS_HOME=/var/jenkins_home
ENV JENKINS_VERSION=2.387.2
ENV JENKINS_SHA=5b80c58b7c99a96b7c1967569be21ef86586e6b93ed424d4f34d2b3d2516cd32

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    python3 \
    python3-pip \
    vim \
    net-tools \
    iputils-ping \
    procps \
    lsof \
    && rm -rf /var/lib/apt/lists/*

# Add Jenkins user
RUN useradd -d "$JENKINS_HOME" -u 1000 -m -s /bin/bash jenkins

# Install Jenkins
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d
RUN curl -fsSL https://get.jenkins.io/war-stable/$JENKINS_VERSION/jenkins.war -o /usr/share/jenkins/jenkins.war \
    && echo "$JENKINS_SHA /usr/share/jenkins/jenkins.war" | sha256sum -c -

# Expose ports for Jenkins
EXPOSE 8080 50000

# Set Python as the default python command
RUN ln -s /usr/bin/python3 /usr/bin/python

# Set up Jenkins to run on start
USER jenkins

# Default command to start Jenkins
ENTRYPOINT ["java", "-jar", "/usr/share/jenkins/jenkins.war"]

# Default arguments for Jenkins
CMD ["--httpPort=8080"]
