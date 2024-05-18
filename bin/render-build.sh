#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean

if [ "$1" == "web" ]; then
  if ! test -f public/sitemap.xml.gz; then
    bundle exec rake sitemap:refresh:no_ping
    bundle exec rake feeds
  fi
fi
