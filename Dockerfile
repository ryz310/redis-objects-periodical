FROM ruby:3.3

RUN mkdir /my_app
WORKDIR /my_app
COPY . /my_app

# Match Gemfile.lock and the supported Ruby baseline.
RUN gem install bundler -v 4.0.23 --no-document && bundle _4.0.23_ install
