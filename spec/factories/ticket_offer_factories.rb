FactoryGirl.define do
  factory :ticket_offer do
    association :organization

    reseller_profile do |to|
      reseller = Factory :organization_with_reselling
      reseller.reseller_profile
    end

    show do |to|
      event = Factory :event, organization: to.organization
      FactoryGirl.create :show, event: event
    end

    section do |to|
      chart = Factory :chart, event: to.show.event, organization: to.organization
      FactoryGirl.create :section, chart: chart
    end
  end
end
