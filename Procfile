web: bundle exec puma -C config/puma.rb
worker: bundle exec rake solid_queue:start
release: bin/rails db:migrate db:migrate:cable db:migrate:queue db:migrate:cache db:seed
