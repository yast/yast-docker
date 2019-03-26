FROM yastdevel/ruby:sle15-sp1
RUN zypper --non-interactive in --force-resolution rubygem-docker-api
COPY . /usr/src/app

