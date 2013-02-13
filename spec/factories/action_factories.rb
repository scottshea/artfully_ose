FactoryGirl.define do
  factory :get_action do
    association :person
    occurred_at { DateTime.now }
  end

  factory :give_action do
    association :person
    subject { FactoryGirl.create(:donation) }
    occurred_at { DateTime.now }
  end
end