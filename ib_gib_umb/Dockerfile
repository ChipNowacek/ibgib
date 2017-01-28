FROM ubuntu:16.04
RUN apt-get update && \
    apt-get install -y libssl1.0.0 postgresql-client && \
    apt-get autoclean

# WebGib uses `convert` from imagemagick
RUN apt-get install -y \
    wget \
    imagemagick

RUN mkdir -p /app
ARG VERSION=0.2.1
# Copy the app over.
COPY rel/ib_gib_umb/releases/${VERSION}/ib_gib_umb.tar.gz /app/ib_gib_umb.tar.gz

# This script waits for postgres to start up before starting the app
COPY scripts/entrypoint.sh /app/entrypoint.sh
# Without chmod, permission denied
RUN chmod +x /app/entrypoint.sh

WORKDIR /app

# Extract the app
RUN tar xvzf ib_gib_umb.tar.gz

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# App only runs on https, but 443 is already taken by nginx-redirect
# EXPOSE 443 80
# Runs on ibgib port
ENV PORT 16816
EXPOSE 16816

# Start the app in the foreground. This prevents it from immediately exiting.
CMD ["/app/bin/ib_gib_umb", "foreground"]
