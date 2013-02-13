require 'ostruct'
FactoryGirl.define do
  factory :customer, :class => OpenStruct do
    first_name = Faker::Name.first_name
    last_name   = Faker::Name.last_name
    phone       = Faker::PhoneNumber.phone_number
    email       = Faker::Internet.email

    trait(:with_id) do
      sequence(:id) {|n| n }
      after(:build) do |customer|
        FakeWeb.register_uri(:post, "http://localhost/payments/customers.json", :body => customer.encode)
        FakeWeb.register_uri(:get, "http://localhost/payments/customers/#{customer.id}.json", :body => customer.encode)
      end
    end
  end

  factory :person_with_address, :class => Person do
    first_name  { Faker::Name.first_name }
    last_name   { Faker::Name.last_name }
    email       { Faker::Internet.email }
    address     { FactoryGirl.build(:address) }
    
    trait(:with_id) do
      sequence(:id) {|n| n }
    end
  end

  factory :credit_card_payment do
    amount 100
  end

  factory :payment, :class => CreditCardPayment do
    amount 100
    customer
  end
end

