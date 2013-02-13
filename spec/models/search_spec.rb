require 'spec_helper'

describe Search do
  disconnect_sunspot
  let(:search) {Search.new.tap {|s| s.organization = organization}}
  let(:organization) {FactoryGirl.create(:organization)}

  context "with an event" do
    before(:each) do
      @event = FactoryGirl.create(:event, organization: organization)
      @show = FactoryGirl.create(:show, event: @event)
      @ticket = FactoryGirl.create(:ticket, show: @show)
      @buyer = FactoryGirl.create(:person, organization: organization)
      @nonbuyer = FactoryGirl.create(:person, organization: organization)
      @ticket.put_on_sale
      @ticket.sell_to @buyer
      search.event_id = @event.id
    end
    specify "#people should return the people that match" do
      search.people.should include @buyer
    end
    specify "#people should not return the people that don't match" do
      search.people.should_not include @nonbuyer
    end
    specify "#description should include relevant text" do
      search.description.should match /Bought tickets for #{@event.name}/
    end
  end

  context "with a discount code" do
    let(:person1) {FactoryGirl.create(:person, organization: organization)}
    let(:person2) {FactoryGirl.create(:person, organization: organization)}
    let(:discount) {FactoryGirl.create(:discount, code: "MUSTANG")}

    before(:each) do
      order = FactoryGirl.create(:order, created_at: 2.months.ago,      person: person1)
      item = FactoryGirl.create(:item, :discount => discount, :order => order)
      item.save

      search.discount_code = "MUSTANG"
    end

    specify "#people should return the people that match" do
      search.people.should      include person1
      search.people.should_not  include person2
    end    
  end

  context "with lifetime values" do
    before(:each) do
      search.min_lifetime_value = 110
      search.max_lifetime_value = 190
    end
    let(:too_high)   {FactoryGirl.create(:person, organization: organization, lifetime_value: 20000)}
    let(:just_right) {FactoryGirl.create(:person, organization: organization, lifetime_value: 15000)}
    let(:too_low)    {FactoryGirl.create(:person, organization: organization, lifetime_value: 10000)}
    specify "#people should return the people that match" do
      search.people.should include just_right
    end
    specify "#people should not return the people that don't match" do
      search.people.should_not include too_high
      search.people.should_not include too_low
    end
    specify "#description should include relevant text" do
      search.description.should match /Have a lifetime value between \$110 and \$190/
    end
  end

  context "with a range of donations" do
    let(:person1) {FactoryGirl.create(:person, organization: organization)}
    let(:person2) {FactoryGirl.create(:person, organization: organization)}
    before(:each) do
      search.min_donations_date   = 1.month.ago
      search.max_donations_date   = 1.month.from_now
      search.min_donations_amount = 5
      search.max_donations_amount = 15
      # Each donation item should be worth $10.
      FactoryGirl.create(:order, created_at: 2.months.ago,      person: person1) << FactoryGirl.create(:donation)
      FactoryGirl.create(:order, created_at: Time.now,          person: person1) << FactoryGirl.create(:donation)
      FactoryGirl.create(:order, created_at: 2.months.from_now, person: person1) << FactoryGirl.create(:donation)
      FactoryGirl.create(:order, created_at: Time.now,          person: person2) << FactoryGirl.create(:donation, amount: 2500)
    end
    specify "#people should return the people that match" do
      search.people.should include person1
    end
    specify "#people should not return the people that don't match" do
      search.people.should_not include person2
    end
    specify "#description should include relevant text" do
      search.description.should match /Made between \$5 and \$15 in donations from #{1.month.ago.strftime('%D')} to #{1.month.from_now.strftime('%D')}/
    end
  end

  context "with a range of donation dates but no amounts" do
    let(:person1) {FactoryGirl.create(:person, organization: organization)}
    let(:person2) {FactoryGirl.create(:person, organization: organization)}
    before(:each) do
      search.min_donations_date   = 1.month.ago
      search.max_donations_date   = 1.month.from_now
      # Each donation item should be worth $10.
      FactoryGirl.create(:order, created_at: 1.month.from_now, person: person1) << FactoryGirl.create(:donation, amount: 1000)
      FactoryGirl.create(:order, created_at: Time.now, person: person2) << FactoryGirl.create(:ticket)
    end
    specify "#people should return the first person with a higher donation amount" do
      search.people.should include person1
    end
    specify "#people should not return the people with no donations (or donations of less than a dollar)" do
      search.people.should_not include person2
    end
    specify "#description should include relevant text" do
      search.description.should match /Made any donations from #{1.month.ago.strftime('%D')} to #{1.month.from_now.strftime('%D')}/
    end
  end

  context "with a zipcode" do
    before(:each) do
      search.zip = 10001
    end
    let(:person1) {FactoryGirl.create(:person, organization: organization, address: FactoryGirl.create(:address, zip: search.zip))}
    let(:person2) {FactoryGirl.create(:person, organization: organization, address: FactoryGirl.create(:address, zip: search.zip + 1))}
    specify "#people should return the people that match" do
      search.people.should include person1
    end
    specify "#people should not return the people that don't match" do
      search.people.should_not include person2
    end
    specify "#description should include relevant text" do
      search.description.should match /Are located within the zipcode of 10001/
    end
  end

  context "with a state" do
    before(:each) do
      search.state = "PA"
    end
    let(:person1) {FactoryGirl.create(:person, organization: organization, address: FactoryGirl.create(:address, state: "PA"))}
    let(:person2) {FactoryGirl.create(:person, organization: organization, address: FactoryGirl.create(:address, state: "NY"))}
    specify "#people should return the people that match" do
      search.people.should include person1
    end
    specify "#people should not return the people that don't match" do
      search.people.should_not include person2
    end
    specify "#description should include relevant text" do
      search.description.should match /Are located within PA/
    end
  end

  context "with a tagging" do
    before(:each) do
      search.tagging = "first_tag"
    end
    let(:person1) {FactoryGirl.create(:person, organization: organization)}
    let(:person2) {FactoryGirl.create(:person, organization: organization)}
    before(:each) do
      person1.tap{|p| p.tag_list = "first_tag, second_tag"}.save!
      person2.tap{|p| p.tag_list = "third_tag"}.save!
    end
    specify "#people should return the people that match" do
      search.people.should include person1
    end
    specify "#people should not return the people that don't match" do
      search.people.should_not include person2
    end
    specify "#description should include relevant text" do
      search.description.should match /Are tagged with first_tag/
    end

  end

end
