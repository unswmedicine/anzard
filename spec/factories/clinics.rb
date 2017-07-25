# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :clinic do
      sequence(:state) do |n| #Pick a random, real state
        states = %w(ACT NSW NT QLD SA TAS VIC WA NZ)
        states[n % states.length]
      end
      sequence(:unit_code, 100) { |n| n }
      unit_name { "Some Unit Name #{unit_code}" }
      sequence(:site_code, 100) { |n| n }
      site_name { "Some Site Name #{site_code}" }
      active true
    end
end