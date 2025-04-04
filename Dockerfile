FROM ruby:3.3.7-slim
ENV RAILS_ENV=${RAILS_ENV}
RUN apt-get update -qq
# Install dependencies for PostgreSQL and PostGIS
RUN apt-get install -y build-essential libpq-dev postgresql-client libproj-dev nodejs less libgeos-dev
# Install dependencies for image attachment processing
RUN apt-get install -y libvips42
RUN mkdir -p /usr/app/landgrab/tmp/pids
WORKDIR /usr/app/landgrab
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
COPY .env .env
COPY wait-for-it.sh wait-for-it.sh
RUN  bundle install
COPY . .
EXPOSE 3000
