FactoryGirl.define do
  factory :person do
    email           { Faker::Internet.email}
    first_name      { Faker::Name.first_name }
    last_name       { Faker::Name.last_name }
    association     :organization
  end

  factory :person_without_email, :parent => :person do
    email nil
  end

  factory :dummy, :parent => :person do
    dummy true
  end
end
