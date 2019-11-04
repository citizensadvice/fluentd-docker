FROM fluent/fluentd:v1.4.2-onbuild-2.0
MAINTAINER ca-devops@citizensadvice.org.uk

USER root

RUN apk add --no-cache --update --virtual .build-deps \
        build-base ruby-dev \
 && gem install fluent-plugin-s3 -v 1.2.0 \
 && gem install fluent-plugin-multi-format-parser -v 1.0.0 \
 && gem install fluent-plugin-ec2-metadata -v 0.1.2 \
 && gem install fluent-plugin-rewrite-tag-filter -v 2.2.0 \
 && gem install fluent-plugin-sumologic_output -v 1.4.1 \
 && gem sources --clear-all \
 && apk del .build-deps \
 && rm -rf /home/fluent/.gem/ruby/2.3.0/cache/*.gem
