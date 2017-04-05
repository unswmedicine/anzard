# Configure test suite for factory girl
# Enables creating factories with "create" rather than "FactoryGirl.create" and "build" instead of "FactoryGirl.build"
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end