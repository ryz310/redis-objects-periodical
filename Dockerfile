FROM ruby:2.7

RUN mkdir /my_app
WORKDIR /my_app
COPY . /my_app

# Match Gemfile.lock and retain compatibility with the Ruby 2.7 baseline.
RUN gem install bundler -v 2.3.26 --no-document && bundle _2.3.26_ install
