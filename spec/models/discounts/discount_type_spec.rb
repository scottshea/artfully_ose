require 'spec_helper'

describe DiscountType do
  disconnect_sunspot
  subject { FactoryGirl.build(:discount) }

  let(:event) { subject.event }
  let(:cart)               {FactoryGirl.create(:cart)}
  let(:included_show_1)    {FactoryGirl.create(:show)}
  let(:included_show_2)    {FactoryGirl.create(:show)}
  let(:unincluded_show)    {FactoryGirl.create(:show)}
  let(:included_section_1) {FactoryGirl.create(:section, name: Faker::Name.last_name)}
  let(:included_section_2) {FactoryGirl.create(:section, name: Faker::Name.last_name)}
  let(:unincluded_section) {FactoryGirl.create(:section, name: Faker::Name.last_name)}
  let(:included_section_1_name) { included_section_1.name }
  let(:included_section_2_name) { included_section_2.name }
  let(:unincluded_section_name) { unincluded_section.name }

  let(:ticket_1_1) {FactoryGirl.create(:ticket, show: included_show_1, section: included_section_1)}
  let(:ticket_2_1) {FactoryGirl.create(:ticket, show: included_show_2, section: included_section_1)}
  let(:ticket_u_1) {FactoryGirl.create(:ticket, show: unincluded_show, section: included_section_1)}
  let(:ticket_1_2) {FactoryGirl.create(:ticket, show: included_show_1, section: included_section_2)}
  let(:ticket_2_2) {FactoryGirl.create(:ticket, show: included_show_2, section: included_section_2)}
  let(:ticket_u_2) {FactoryGirl.create(:ticket, show: unincluded_show, section: included_section_2)}
  let(:ticket_1_u) {FactoryGirl.create(:ticket, show: included_show_1, section: unincluded_section)}
  let(:ticket_2_u) {FactoryGirl.create(:ticket, show: included_show_2, section: unincluded_section)}
  let(:ticket_u_u) {FactoryGirl.create(:ticket, show: unincluded_show, section: unincluded_section)}

  let(:eligible_ticket_scenarios) {[
    {:description => "no shows or sections",
      :shows => [],
      :sections => [],
      :tickets =>[ticket_1_1, ticket_2_1, ticket_u_1, ticket_1_2, ticket_2_2, ticket_u_2, ticket_1_u, ticket_2_u, ticket_u_u]},
    {:description => "one show",
      :shows => [included_show_1],
      :sections => [],
      :tickets =>[ticket_1_1, ticket_1_2, ticket_1_u]},
    {:description => "two shows",
      :shows => [included_show_1, included_show_2],
      :sections => [],
      :tickets =>[ticket_1_1, ticket_2_1, ticket_1_2, ticket_2_2, ticket_1_u, ticket_2_u]},
    {:description => "one section",
      :shows => [],
      :sections => [included_section_1_name],
      :tickets =>[ticket_1_1, ticket_2_1, ticket_u_1]},
    {:description => "two sections",
      :shows => [],
      :sections => [included_section_1_name, included_section_2_name],
      :tickets =>[ticket_1_1, ticket_2_1, ticket_u_1, ticket_1_2, ticket_2_2, ticket_u_2]},
    {:description => "one show and one section",
      :shows => [included_show_1],
      :sections => [included_section_1_name],
      :tickets =>[ticket_1_1]},
    {:description => "multiple shows and sections",
      :shows => [included_show_1, included_show_2],
      :sections => [included_section_1_name, included_section_2_name],
      :tickets =>[ticket_1_1, ticket_2_1, ticket_1_2, ticket_2_2]}
  ]}

  describe "#eligible_tickets" do
    specify "should return the matching tickets for" do
      cart.tickets << [ticket_1_1, ticket_2_1, ticket_u_1, ticket_1_2, ticket_2_2, ticket_u_2, ticket_1_u, ticket_2_u, ticket_u_u]
      subject.cart = cart
      eligible_ticket_scenarios.each do |scenario|
        puts scenario[:description]
        subject.shows = scenario[:shows]
        subject.sections = scenario[:sections]
        subject.eligible_tickets.collect(&:id).should =~ scenario[:tickets].collect(&:id)
      end
    end
  end

end