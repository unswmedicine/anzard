FactoryGirl.define do
  factory :capturesystem do
    sequence(:name, 100) { |n| "capturesystem_#{n}" }
    sequence(:base_url, 100) { |n| "http://capturesystem_#{n}.localhost:3000" }
  end
end
