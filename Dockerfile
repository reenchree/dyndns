FROM ruby:3.4-alpine

WORKDIR /app

COPY dyndns.rb .
COPY Gemfile Gemfile.lock .

RUN apk add --no-cache build-base #libffi-dev
ENV BUNDLE_WITHOUT="test development"
RUN bundle install

CMD ["ruby", "/app/dyndns.rb"]
