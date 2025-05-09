FROM fluent/fluentd:v1.18.0-1.0
LABEL author="ca-devops@citizensadvice.org.uk"

USER root

RUN apk add --no-cache --update --virtual .build-deps build-base ruby-dev \
        && gem install fluent-plugin-s3 -v 1.8.3 \
        && gem install fluent-plugin-multi-format-parser -v 1.1.0 \
        && gem install fluent-plugin-ec2-metadata -v 0.1.3 \
        && gem install fluent-plugin-rewrite-tag-filter -v 2.4.0 \
        && gem install fluent-plugin-sumologic_output -v 1.10.0 \
        && gem install fluent-plugin-parser-cri -v 0.1.1 \
        && gem install fluent-plugin-concat -v 2.5.0 \
        && gem sources --clear-all \
        && apk del .build-deps \
        && rm -rf /home/fluent/.gem/ruby/*/cache/*.gem

COPY --chown=fluent:fluent fluent.conf /fluentd/etc/fluent.conf
