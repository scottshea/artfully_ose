FactoryGirl.define do
factory :organization do
  name { Faker::Company.name }
  email { Faker::Internet.email }
  time_zone { "Eastern Time (US & Canada)" }
end

factory :organization_with_timezone, :parent => :organization do
  after(:build) do |organization|
    organization.time_zone = 'Eastern Time (US & Canada)'
  end
end

factory :organization_with_bank_account, :parent => :organization do
  after(:create) do |organization|
    organization.bank_account = FactoryGirl.create(:bank_account)
  end
end

factory :organization_with_ticketing, :parent => :organization do
  after(:create) { |organization| FactoryGirl.create(:ticketing_kit, :state => :activated, :organization => organization) }
end

factory :organization_with_donations, :parent => :organization do
  after(:create) { |organization| FactoryGirl.create(:regular_donation_kit, :state => :activated, :organization => organization) }
end

factory :connected_organization, :parent => :organization do
  association :fiscally_sponsored_project
  fa_member_id "1"
end

end