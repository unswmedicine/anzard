# Follows Ruby and Docker compose reference at https://docs.docker.com/compose/rails/
FROM ruby:2.4

# Install apt based dependencies required to run Rails as well as RubyGems.
RUN apt-get update && apt-get install -y build-essential nodejs

# Configure the main working directory. This is the base directory used in any further RUN, COPY, and ENTRYPOINT commands.
RUN mkdir -p /app
WORKDIR /app

# Copy the Gemfile as well as the Gemfile.lock and install the RubyGems. This is a separate step so the dependencies
# will be cached unless changes to one of those two files are made.
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN gem install bundler && bundle install --jobs 20 --retry 5

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000
RUN export RAILS_ENV=development
COPY ./docker_dir/start_app.sh /usr/bin/start_app.sh
RUN chmod +x /usr/bin/start_app.sh
CMD ["start_app.sh"]
