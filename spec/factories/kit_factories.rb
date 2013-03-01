FactoryGirl.define do
  factory :ticketing_kit do
    association :organization
  end

  factory :regular_donation_kit do
    association :organization
  end

  factory :sponsored_donation_kit do
    association :organization
  end

  factory :reseller_kit do
    association :organization
  end
end
