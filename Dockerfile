FROM ruby:2.5.3-alpine3.8

LABEL maintainer.url="https://github.com/parabolic"
LABEL description="A dockerized jekyll that regenerates the site on file change."
LABEL maintainer.name="Nikola Velkovski"

ARG UID
ARG GID
ARG USERNAME

ENV APP_HOME="/app"

RUN apk add --update \
    build-base

WORKDIR ${APP_HOME}

COPY Gemfile* ./

RUN bundle install -j "$(getconf _NPROCESSORS_ONLN)"

# Run as the user specified from docker-compose.
USER ${UID}:${GID}
