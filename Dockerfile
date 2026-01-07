# Use Ruby 3.3.0
FROM ruby:3.3.0-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    libvips \
    nodejs \
    npm \
    curl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set working directory
WORKDIR /rails

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy package files and install npm packages
COPY package.json package-lock.json ./
RUN npm install --legacy-peer-deps

# Copy application code
COPY . .

# Precompile assets
RUN bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start server
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
