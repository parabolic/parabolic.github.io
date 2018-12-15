FROM ruby:2.5.3-alpine3.8

LABEL maintainer.url="https://github.com/parabolic"
LABEL description="A dockerized jekyll that has live updates"
LABEL maintainer.name="Nikola Velkovski"

# Remove the defaults so that they need to be set
ARG UID
ARG GID
ARG USERNAME

ENV APP_HOME="/app"

RUN apk add --update \
    build-base

# We need to check if user/group are present and if not then create it.
 RUN if getent group ${GID}; then \
   echo "The group exists, doing nothing."; \
   else \
     echo "The group is not there, creating it."; \
     addgroup -g ${GID} ${USERNAME} &&\
     adduser -D -u ${UID} -G ${USERNAME} ${USERNAME} -h /home/${USERNAME} && \
     mkdir -p /home/${USERNAME} &&\
     chown -R ${UID}:${GID} /home/${USERNAME}; \
   fi

RUN mkdir -p ${APP_HOME}

VOLUME ["${APP_HOME}"]

WORKDIR ${APP_HOME}

COPY Gemfile* ./

RUN bundle install

COPY . ./

RUN chown -R ${UID}:${GID} .

# Run as the user specified from docker-compose.
USER ${UID}:${GID}
