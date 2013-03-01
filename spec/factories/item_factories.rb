FactoryGirl.define do
  factory :item do
    product { FactoryGirl.create(:sold_ticket) }
    association :order
  end

  factory :free_item, :parent => :item do
    product { FactoryGirl.create(:free_ticket) }
    association :order
  end

  factory :fully_discounted_item, :parent => :item do
    product { FactoryGirl.create(:fully_discounted_ticket) }
    association :discount
  end

  factory :settled_item, :class => Item do
    product { FactoryGirl.create(:ticket, :state => :sold) }
    after(:build) do |i|
      i.state="settled"
    end
  end

  factory :comped_item, :class => Item do
    product { FactoryGirl.create(:ticket, :state => :comped) }
    after(:build) do |i|
      i.state="comped"
    end
  end

  factory :exchanged_item, :class => Item do
    product { FactoryGirl.create(:ticket, :state => :on_sale) }
    after(:build) do |i|
      i.state="exchanged"
    end
  end

  factory :exchangee_item, :class => Item do
    product { FactoryGirl.create(:ticket, :state => :sold) }
    after(:build) do |i|
      i.state="exchangee"
    end
  end

  factory :refunded_item, :class => Item do
    product { FactoryGirl.create(:ticket, :state => :on_sale) }
    after(:build) do |i|
      i.state="refunded"
    end
  end
end