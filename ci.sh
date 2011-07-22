#!/bin/bash -e
env

git checkout -B ci_temporary
git branch -D $BRANCH || true
git fetch
git checkout -f $BRANCH
git clean -df

bundle install --deployment

bundle exec rspec spec

exit $?
