# Configure test suite for factory girl
# Enables creating factories with "create" rather than "FactoryBot.create" and "build" instead of "FactoryBot.build"
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  FactoryBot.use_parent_strategy = false
end