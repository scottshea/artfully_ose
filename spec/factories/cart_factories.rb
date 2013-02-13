FactoryGirl.define do
  factory :cart do
  end

  factory :cart_with_items, :parent => :cart do
    after(:create) do |order|
      order.tickets << 3.times.collect { FactoryGirl.create(:ticket) }
      order.donations << FactoryGirl.create(:donation)
    end
  end

  factory :cart_with_free_items, :parent => :cart do
    after(:create) do |order|
      order.tickets << 3.times.collect { FactoryGirl.create(:free_ticket) }
    end
  end

  factory :cart_with_only_tickets, :parent => :cart do  
  end
end