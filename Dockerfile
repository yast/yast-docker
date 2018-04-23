FROM yastdevel/ruby:sle15
RUN zypper --non-interactive in --force-resolution rubygem-docker-api
COPY . /usr/src/app

