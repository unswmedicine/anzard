#!/bin/bash
wget --retry-connrefused --waitretry=5 --read-timeout=10 --timeout=10 --tries=10 -nv \
db:3306 -O - > /dev/null \
&& \
(bundle exec rake db:migrate || SKIP_PRELOAD_MODELS=skip bundle exec rake db:setup db:populate) \
&& \
rails server -b 0.0.0.0

