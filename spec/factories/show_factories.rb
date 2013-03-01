FactoryGirl.define do
  sequence(:datetime) {|n| DateTime.now + 7.days + n.minutes}

  factory :show do
    datetime { generate :datetime }
    association :organization
    association :event
    association :chart, :factory => :assigned_chart
  end

  factory :show_with_tickets, :parent => :show do
    after(:create) do |show|
      # tickets.each do |t|
      # end
      show.build!
      show.publish!
    end
  end

  factory :settleable_show, :parent => :show_with_tickets do
    association :organization, :factory => :organization_with_bank_account
    after(:create) do |show|
      show.tickets.each do |ticket|
        ticket.sell_to(FactoryGirl.build(:person))
        Item.for(ticket).save
      end
    end
  end

  factory :expired_show, :parent => :show do
    datetime { DateTime.now - 1.day}
  end
end
