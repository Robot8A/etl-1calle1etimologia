FROM ubuntu:latest
LABEL maintainer="aumpfbahn@gmail.com"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update \
  && apt-get -y install postgresql-client postgis osm2pgsql curl osmium-tool npm \
  && apt-get -y clean

RUN service postgresql start \
  && su - postgres -c "createuser --superuser root; createdb osm" \
  && psql -d osm -c 'CREATE EXTENSION postgis; CREATE EXTENSION unaccent;'

COPY . /root
WORKDIR /root

ENTRYPOINT service postgresql start && bash
