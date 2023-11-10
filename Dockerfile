FROM buildpack-deps:jessie-curl
LABEL MAINTAINER="José Carlos Paiva <josepaiva94@gmail.com>,José Paulo Leal <zp@dcc.fc.up.pt>"

# Mooshak environment variables
ENV MOOSHAK_VERSION 1.6.3

# update && upgrade && install necessary packages
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y apt-utils build-essential

# set locale to UTF8
RUN apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# language environment variables
ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

# install Mooshak prerequisites
RUN apt-get install -y tcl apache2 apache2-suexec supervisor \
    lpr time cron host rsync libxml2-utils xsltproc

# cleanup unnecessary files
RUN apt-get clean && apt-get autoremove -y

# configure apache modules
RUN bash -c '\
  cd /etc/apache2/;\
  mkdir -p mods-enabled;\
  cd mods-enabled;\
  ln -s ../mods-available/userdir.conf;\
  ln -s ../mods-available/userdir.load;\
  ln -s ../mods-available/suexec.load;\
  ln -s ../mods-available/cgi.load;'

ADD apache-userdir.conf /etc/apache2/mods-available/userdir.conf

RUN mkdir -p /var/run/apache2

# install Mooshak 1.x
ADD https://mooshak.dcc.fc.up.pt/download/mooshak-${MOOSHAK_VERSION}.tgz mooshak-${MOOSHAK_VERSION}.tgz
RUN tar xzf mooshak-${MOOSHAK_VERSION}.tgz
RUN cd mooshak-${MOOSHAK_VERSION} && sed -e 's/proc check_suexec {} {/proc check_suexec {} { return;/' < install > install-modded
RUN cd mooshak-${MOOSHAK_VERSION} && sh install-modded

# remove installation garbage
RUN rm -rf mooshak-${MOOSHAK_VERSION}.tgz mooshak-${MOOSHAK_VERSION}

EXPOSE 80
VOLUME /home/mooshak/data

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
