FROM ruby:2.3

ENV WORK_DIR /usr/lib/couchrest_model

RUN mkdir -p $WORK_DIR
WORKDIR $WORK_DIR

COPY . $WORK_DIR

RUN bundle install --jobs=3 --retry=3

