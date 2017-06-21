# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :clinic do
      sequence(:state) do |n| #Pick a random, real state
        states = %w(ACT NSW Qld SA NT Vic WA New\ Zealand)
        states[n % states.length]
      end
      sequence(:unit_name) { |n| "Some Unit Name #{n}" }
      sequence(:unit_code) { |n| "Some Unit #{n}" }
      sequence(:site_name) { |n| "Some Site Name #{n}" }
      sequence(:site_code) { |n| "Some Site #{n}" }
    end
end