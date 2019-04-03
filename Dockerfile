FROM registry.opensuse.org/yast/head/containers/yast-ruby:latest
RUN zypper --non-interactive in --force-resolution rubygem-docker-api
COPY . /usr/src/app

