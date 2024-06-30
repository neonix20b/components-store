#!/usr/bin/env bash
# exit on error
set -o errexit

source_cache_dir="public"

if [[ -d "$XDG_CACHE_HOME/$source_cache_dir" ]]; then
  cp "$XDG_CACHE_HOME/$source_cache_dir/*.gz" $source_cache_dir
else
  mkdir "$XDG_CACHE_HOME/$source_cache_dir"
fi

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean

if [ "$1" == "web" ]; then
  if ! test -f public/sitemap.xml.gz; then
    bundle exec rake sitemap:refresh:no_ping
    bundle exec rake feeds:yandex
    # bundle exec rake feeds:google

    cp $source_cache_dir/*.gz "$XDG_CACHE_HOME/$source_cache_dir"
  fi
fi
