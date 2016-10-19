FROM ubuntu:16.04
RUN apt-get update && \
    apt-get install -y libssl1.0.0 postgresql-client && \
    apt-get autoclean
RUN mkdir -p /app
ARG VERSION=0.1.0
COPY rel/ib_gib_umb/releases/${VERSION}/ib_gib_umb.tar.gz /app/ib_gib_umb.tar.gz
COPY scripts/wait-for-postgres.sh /app/wait-for-postgres.sh
WORKDIR /app
RUN tar xvzf ib_gib_umb.tar.gz
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PORT 80
CMD ["/app/bin/ib_gib_umb", "foreground"]
