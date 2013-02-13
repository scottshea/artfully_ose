FactoryGirl.define do
  factory :section do
    name "General"
    capacity 5
    price 1000
    storefront true
    box_office true
  end

  factory :free_section, :class => Section do
    name 'Balcony'
    capacity 5
    price 0
    storefront true
    box_office true
  end
end
