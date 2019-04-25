FROM fluent/fluentd:v1.3.3-onbuild-1.0
MAINTAINER ca-devops@citizensadvice.org.uk

USER root

RUN apk add --no-cache --update --virtual .build-deps \
        build-base ruby-dev \
 && gem install \
        fluent-plugin-s3 \
        fluent-plugin-multi-format-parser \
        fluent-plugin-ec2-metadata \
        fluent-plugin-rewrite-tag-filter \
        fluent-plugin-sumologic_output \
 && gem sources --clear-all \
 && apk del .build-deps \
 && rm -rf /home/fluent/.gem/ruby/2.3.0/cache/*.gem
