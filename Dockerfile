FROM amd64/ruby:2.7.5-alpine3.15

ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

ENV RACK_ENV=production
ENV PORT=8080

EXPOSE 8080

WORKDIR /app
ADD Gemfile Gemfile.lock .ruby-version /app/

ENV GEMS_DEPS make gcc g++ libffi-dev libpq-dev
ENV MUSL_LOCALE_DEPS cmake make musl-dev gcc gettext-dev libintl
ENV MUSL_LOCPATH /usr/share/i18n/locales/musl

RUN apk update && apk upgrade --no-cache
# Do we need nodejs
RUN apk add --no-cache supervisor supercronic $GEMS_DEPS $MUSL_LOCALE_DEPS
RUN wget https://gitlab.com/rilian-la-te/musl-locales/-/archive/master/musl-locales-master.zip \
    && unzip musl-locales-master.zip && cd musl-locales-master                                 \
    && cmake -DLOCALE_PROFILE=OFF -D CMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install  \
    && cd .. && rm -r musl-locales-master

RUN gem install bundler -v 2.2.33
RUN bundle config set --local deployment 'true'
RUN bundle install

# Clean-up
RUN apk del $GEMS_DEPS $MUSL_LOCALE_DEPS
RUN rm -rf /tmp/* /var/tmp/*

ADD docker/supervisord.conf /etc/supervisord.conf
ADD docker/start.sh /app/
ADD . /app

RUN useradd -m stringer
RUN chown -R stringer:stringer /app
USER stringer

CMD /app/start.sh
