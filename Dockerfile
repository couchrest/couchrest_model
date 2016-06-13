FROM ruby:2.3

ENV WORK_DIR /usr/lib/couchrest_model

RUN mkdir -p $WORK_DIR

COPY . $WORK_DIR
RUN cd $WORK_DIR && bundle install

WORKDIR $WORK_DIR
