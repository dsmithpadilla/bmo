FROM mozillabteam/bmo-perl-slim:20240822.1 AS base

ENV DEBIAN_FRONTEND noninteractive

ARG CI
ARG CIRCLE_SHA1
ARG CIRCLE_BUILD_URL

ENV CI=${CI}
ENV CIRCLE_BUILD_URL=${CIRCLE_BUILD_URL}
ENV CIRCLE_SHA1=${CIRCLE_SHA1}

ENV LOG4PERL_CONFIG_FILE=log4perl-json.conf

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y rsync

# we run a loopback logging server on this TCP port.
ENV LOGGING_PORT=5880

ENV LOCALCONFIG_ENV=1

WORKDIR /app

COPY . /app

RUN chown -R app:app /app && \
    perl -I/app -I/app/local/lib/perl5 -c -E 'use Bugzilla; BEGIN { Bugzilla->extensions }' && \
    perl -c /app/scripts/entrypoint.pl

USER app

RUN perl checksetup.pl --no-database --default-localconfig && \
    rm -rf /app/data /app/localconfig && \
    mkdir /app/data

EXPOSE 8000

ENTRYPOINT ["/app/scripts/entrypoint.pl"]
CMD ["httpd"]

FROM base AS TEST

USER root

RUN apt-get install -y curl firefox-esr lsof

RUN curl -L https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz -o /tmp/geckodriver.tar.gz \
  && cd /tmp \
  && tar zxvf geckodriver.tar.gz \
  && mv geckodriver /usr/bin/geckodriver

USER app
