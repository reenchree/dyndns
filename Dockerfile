FROM ruby:3.4.11-alpine3.24@sha256:aa205a3ebbf558c304cd135c197af8e80cf6c26193ec4b5862763562f1c38426

WORKDIR /app

COPY dyndns.rb .
COPY main.rb .
COPY Gemfile Gemfile.lock .

RUN apk add --no-cache build-base

RUN bundle config set without 'test development' \
 && bundle install --jobs 4


CMD ["ruby", "/app/main.rb"]
