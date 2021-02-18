FactoryBot.define do
  factory :capturesystem_user do
    capturesystem { association :capturesystem }
    user { association :user }
    access_status { CapturesystemUser::STATUS_UNAPPROVED }
  end
end
