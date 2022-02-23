# syntax=docker/dockerfile:1.3.1
FROM amd64/ruby:2.7.5-alpine3.15

ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

ENV RACK_ENV=production
ENV PORT=8080

EXPOSE 8080

ENV CONTAINER_DEPS supervisor supercronic
ENV GEMS_DEPS libpq libpq-dev nodejs openssl-dev
ENV GEMS_BUILD_DEPS make gcc g++ libffi-dev
ENV MUSL_LOCALE_DEPS cmake make musl-dev gcc gettext-dev libintl
ENV MUSL_LOCPATH /usr/share/i18n/locales/musl
ENV DEV_DEPS_TO_REMOVE cmake make gcc g++ gettext-dev libc-dev libffi-dev musl-dev


RUN gem install bundler -v 2.2.33
RUN apk add --no-cache $CONTAINER_DEPS $GEMS_DEPS $GEMS_BUILD_DEPS $MUSL_LOCALE_DEPS
RUN wget https://gitlab.com/rilian-la-te/musl-locales/-/archive/master/musl-locales-master.zip \
    && unzip musl-locales-master.zip && cd musl-locales-master                                 \
    && cmake -DLOCALE_PROFILE=OFF -D CMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install  \
    && cd .. && rm -r musl-locales-master && rm musl-locales-master.zip

# Create `stringer` group and user
RUN addgroup -S stringer && adduser -S stringer -G stringer

COPY docker/supervisord.conf /etc/supervisord.conf
COPY --chown=stringer:stringer . docker/start.sh /app/

WORKDIR /app

USER stringer
RUN bundle config set --local deployment 'true' && bundle install --jobs=3 --retry=3

# Clean-up
USER root
RUN apk del $DEV_DEPS_TO_REMOVE
RUN rm -rf /app/docker/ /tmp/* /var/tmp/*

# Run all future commands as `stringer` user
USER stringer

# Start the app
CMD ["/app/start.sh"]
