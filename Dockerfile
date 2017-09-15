FROM ruby:2.4.1-alpine3.6
RUN apk add --no-cache build-base
ADD . /clerk
WORKDIR /clerk
RUN apk add --no-cache postgresql-dev
RUN bundle install

