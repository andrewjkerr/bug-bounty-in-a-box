FROM ruby:2.6.3

RUN mkdir -p /app

WORKDIR /app

# Add the Gemfile & lockfile first to allow for caching.
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install

# Then add the rest of the files.
ADD . /app

EXPOSE 4567

ENTRYPOINT ["ruby", "app.rb"]
