FROM ubuntu:latest
LABEL maintainer="aumpfbahn@gmail.com"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y \
    postgresql postgresql-contrib postgresql-client \
    postgis \
    osm2pgsql \
    osmium-tool \
    curl ca-certificates \
    nodejs npm \
    locales \
    coreutils gawk grep sed util-linux ncurses-bin \
    bash \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 \
 && apt-get clean

RUN service postgresql start \
 && su - postgres -c "createuser --superuser root; createdb osm" \
 && psql -d osm -c 'CREATE EXTENSION postgis; CREATE EXTENSION unaccent;'

COPY . /root
WORKDIR /root

ENTRYPOINT ["/bin/sh", "-c", "service postgresql start && bash"]
