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

# Precompile assets with dummy secret key base
# Railway will provide the real RAILS_MASTER_KEY at runtime
ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV}
ENV SECRET_KEY_BASE=dummy_secret_key_base_for_asset_compilation
ENV RAILS_MASTER_KEY=dummy_master_key_for_asset_compilation_only_do_not_use_in_production

# Disable database and bootsnap during asset precompilation
RUN DISABLE_DATABASE=1 bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start server
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
