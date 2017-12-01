FROM yastdevel/ruby
RUN zypper --non-interactive in --force-resolution rubygem-docker-api
COPY . /usr/src/app

