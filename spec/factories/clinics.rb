# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :clinic do
      sequence(:state) do |n| #Pick a random, real state
        states = %w(ACT NSW NT QLD SA TAS VIC WA NZ)
        states[n % states.length]
      end
      sequence(:unit_name) { |n| "Some Unit Name #{n}" }
      sequence(:unit_code, 100) { |n| n }
      sequence(:site_name) { |n| "Some Site Name #{n}" }
      sequence(:site_code, 100) { |n| n }
      active true
    end
end