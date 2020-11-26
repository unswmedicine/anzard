#!/bin/bash
wget --retry-connrefused --waitretry=5 --read-timeout=10 --timeout=10 --tries=10 -nv \
db:3306 -O - > /dev/null \
&& \
gem install bundler && bundle install --jobs 20 --retry 5 \
&& \
(bundle exec rake db:migrate || SKIP_PRELOAD_MODELS=skip bundle exec rake db:setup db:populate) \
&& \
bundle exec jekyll build --source manual/ --destination public/user_manual/ \
&& \
bundle exec rake app:generate_secret \
&& \
bundle exec script/delayed_job -i anzard start \
&& \
(
    if [ "$1" == "passenger" ];
    then 
        #prod_like
        bundle exec rake assets:clobber assets:precompile && bundle exec passenger start;
    else
        #dev
        rm -vfr /app/public/assets && bundle exec rails server -b 0.0.0.0;
    fi
)

