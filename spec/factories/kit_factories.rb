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
  
  factory :mailchimp_kit do |t|
    t.association :organization
    t.settings { { :api_key => "api_key-us5", :attached_lists => [{:list_id => "88a334b", :list_name => "First List"}] } }
  end
end
