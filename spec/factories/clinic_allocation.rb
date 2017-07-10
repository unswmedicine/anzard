# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :clinic_allocation do
    association :user
    association :clinic
  end
end