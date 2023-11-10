FROM alpine:3.7
LABEL MAINTAINER="José Carlos Paiva <josepaiva94@gmail.com>,José Paulo Leal <zp@dcc.fc.up.pt>"

# Mooshak environment variables
ENV MOOSHAK_VERSION 1.6.3

# language environment variables
ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    ALPINE_GLIBC_VERSION="2.27-r0" \
    ALPINE_GLIBC_KEY_URL="https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
    ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download/"

# update && upgrade && install necessary packages
RUN apk update
RUN apk upgrade
RUN apk --no-cache --update add build-base

# install language pack
RUN apk --no-cache --update add ca-certificates wget && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub ${ALPINE_GLIBC_KEY_URL} && \
    wget ${ALPINE_GLIBC_BASE_URL}/${ALPINE_GLIBC_VERSION}/glibc-${ALPINE_GLIBC_VERSION}.apk && \
    wget ${ALPINE_GLIBC_BASE_URL}/${ALPINE_GLIBC_VERSION}/glibc-bin-${ALPINE_GLIBC_VERSION}.apk && \
    wget ${ALPINE_GLIBC_BASE_URL}/${ALPINE_GLIBC_VERSION}/glibc-i18n-${ALPINE_GLIBC_VERSION}.apk && \
    apk add glibc-bin-${ALPINE_GLIBC_VERSION}.apk glibc-i18n-${ALPINE_GLIBC_VERSION}.apk glibc-${ALPINE_GLIBC_VERSION}.apk && \
    rm -rf *.apk /etc/apk/keys/sgerrand.rsa.pub

COPY ./locale.md /locale.md
RUN cat locale.md | xargs -i /usr/glibc-compat/bin/localedef -i {} -f UTF-8 {}.UTF-8

# install Mooshak prerequisites
RUN apk --no-cache --update add bash tcl apache2 apache2-ctl apache2-utils \
    file shadow tini openrc curl supervisor cups-client dcron bind-tools \
    rsync libxml2-utils libxslt

# configure apache modules
# RUN bash -c '\
#   cd /etc/apache2/;\
#   mkdir mods-enabled;\
#   cd mods-enabled;\
#   ln -s ../mods-available/userdir.conf;\
#   ln -s ../mods-available/userdir.load;\
#   ln -s ../mods-available/suexec.load;\
#   ln -s ../mods-available/mpm_prefork.conf;\
#   ln -s ../mods-available/mpm_prefork.load;\
#   ln -s ../mods-available/cgi.load;'

# ADD apache-userdir.conf /etc/apache2/mods-available/userdir.conf
ADD httpd.conf /etc/apache2/httpd.conf

RUN mkdir -p /var/run/apache2

# prevent mailbox creatione
RUN echo "CREATE_MAIL_SPOOL=no" >> /etc/default/useradd

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
