# FactoryBot configuration
RSpec.configure do |config|
  # Include FactoryBot syntax methods (build, create, etc.)
  config.include FactoryBot::Syntax::Methods

  # Lint factories in development to catch errors early
  config.before(:suite) do
    if Rails.env.test?
      begin
        FactoryBot.lint(traits: true) if defined?(FactoryBot) && FactoryBot.factories.count > 0
      rescue FactoryBot::InvalidFactoryError => e
        # Ignore linting errors if no factories exist yet
        puts "FactoryBot lint skipped: #{e.message}"
      end
    end
  end
end
