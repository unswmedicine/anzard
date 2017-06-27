FactoryGirl.define do
  factory :basic_user, class: :user do
    first_name "Fred"
    last_name "Bloggs"
    password "Pas$w0rd"
    sequence(:email) { |n| "#{n}@intersect.org.au" }

    factory :user do
      transient do
        clinics_count 0
      end

      after(:create) do |user, evaluator|
        create_list(:clinic, evaluator.clinics_count, users: [user])
      end
    end

    factory :super_user do
      role { |r| Role.superuser_roles.first || r.association(:role, name: Role::SUPER_USER) }
    end
  end

end