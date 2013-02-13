FactoryGirl.define do
  factory :donation do
    amount 1000
    association :organization
  end
end