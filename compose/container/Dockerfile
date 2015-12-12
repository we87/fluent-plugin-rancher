FROM ubuntu:14.04
MAINTAINER BinZhao "antmanler@gmail.com"

# Ensure there are enough file descriptors for running Fluentd.
RUN ulimit -n 65536

# Disable prompts from apt.
ENV DEBIAN_FRONTEND noninteractive

# Install prerequisites.
RUN apt-get update && \
    apt-get install -y -q curl make g++ && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Fluentd.
RUN /usr/bin/curl -L https://td-toolbelt.herokuapp.com/sh/install-ubuntu-trusty-td-agent2.sh | sh && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Change the default user and group to root.
# Needed to allow access to /var/log/docker/... files.
RUN sed -i -e "s/USER=td-agent/USER=root/" -e "s/GROUP=td-agent/GROUP=root/" /etc/init.d/td-agent

# Install the Elasticsearch Fluentd plug-in.
RUN td-agent-gem install fluent-plugin-elasticsearch fluent-plugin-rancher

# Copy the Fluentd configuration file.
COPY td-agent.conf /etc/td-agent/td-agent.conf

ADD ./run.sh /run.sh
RUN chmod +x /run.sh

# Run the Fluentd service.
CMD /run.sh td-agent
