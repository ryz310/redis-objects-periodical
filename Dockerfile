FROM ruby:2.6

RUN mkdir /my_app
WORKDIR /my_app
COPY . /my_app

RUN gem install bundler && bundle
