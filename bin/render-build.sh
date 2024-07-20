#!/usr/bin/env bash
# exit on error
set -o errexit

source_cache_dir="$XDG_CACHE_HOME/rails_public"

if [[ -d "$source_cache_dir" ]]; then
  cp $source_cache_dir/*.gz public
fi

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean

if [ "$1" == "web" ]; then
  rake webhooks RAILS_ENV=production
  if ! test -f public/sitemap.xml.gz; then
    bundle exec rake sitemap:refresh:no_ping
    bundle exec rake feeds:yandex
    # bundle exec rake feeds:google

    mkdir -p $source_cache_dir
    cp public/*.gz $source_cache_dir
  fi
fi
