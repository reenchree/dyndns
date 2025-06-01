FROM ruby:3.4-alpine

WORKDIR /app

COPY dyndns.rb .
COPY main.rb .
COPY Gemfile Gemfile.lock .

RUN apk add --no-cache build-base

RUN bundle config set without 'test development' \
 && bundle install --jobs 4


CMD ["ruby", "/app/main.rb"]
