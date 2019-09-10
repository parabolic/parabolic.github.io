FROM ruby:2.6.3-alpine

LABEL maintainer.url="https://github.com/parabolic"
LABEL description="A dockerized jekyll that regenerates the site on file change."
LABEL maintainer.name="Nikola Velkovski"

ARG UID
ARG GID

ENV APP_HOME="/app"

RUN apk add --update \
    build-base

WORKDIR ${APP_HOME}

COPY Gemfile* ./

RUN bundle install -j "$(getconf _NPROCESSORS_ONLN)"

# Run as the user with the UID and GID from the arguments.
USER ${UID}:${GID}
