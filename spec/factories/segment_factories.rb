FactoryGirl.define do
  factory :segment do
    name "Some List Segment"
    association :organization
  end
end