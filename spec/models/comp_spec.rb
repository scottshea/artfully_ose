require 'spec_helper'

describe Comp do
  disconnect_sunspot
  let(:organization) { FactoryGirl.build(:organization) }
  let(:show) { FactoryGirl.build(:show) }
  let(:benefactor) { FactoryGirl.build(:user_in_organization) }
  let(:tickets) { 10.times.collect { FactoryGirl.build(:ticket, :show => show) } }
  let(:recipient) { FactoryGirl.build(:person, :organization => benefactor.current_organization) }

  # TODO: Fix these specs! Almost none of them are working. Change build to create?
  # describe "should not be valid if" do
  #   it "it doesnt have a recipient" do
  #     @comp = Comp.new(show, [], nil, benefactor)
  #     @comp.should_not be_valid
  #   end
    
  #   it "it doesnt have a benefactor" do
  #     @comp = Comp.new(show, [], recipient, nil)
  #     @comp.should_not be_valid
  #   end
    
  #   it "the benefactor and recipient are from different organizations" do
  #     new_recipient = FactoryGirl.build(:person)
  #     selected_tickets = [] 
  #     (0..2).each do |i|
  #       selected_tickets << tickets[i].id
  #     end
  #     @comp = Comp.new(show, selected_tickets, new_recipient, benefactor)
  #     @comp.should_not be_valid
  #   end
  # end
  
  # describe "should be valid if" do     
  #   it "callers pass a recipient_id" do
  #     @comp = Comp.new(show, [], recipient.id, benefactor)
  #     @comp.should be_valid
  #   end
           
  #   it "it has a show, tickets, recipient and benefactor" do 
  #     selected_tickets = [] 
  #     (0..2).each do |i|
  #       selected_tickets << tickets[i].id
  #     end
  #     @comp = Comp.new(show, selected_tickets, recipient, benefactor)
  #     @comp.should be_valid
  #   end
    
  #   it "the benefactor and recipient are from the same organization" do
  #     selected_tickets = [] 
  #     (0..2).each do |i|
  #       selected_tickets << tickets[i].id
  #     end
  #     @comp = Comp.new(show, selected_tickets, recipient, benefactor)
  #     @comp.should be_valid
  #   end
  # end

  # describe "passing ticket ids instead of actual tickets" do
  #   before(:each) do 
  #     selected_tickets = [] 
  #     (0..2).each do |i|
  #       selected_tickets << tickets[i].id
  #     end
  #     @comp = Comp.new(show, selected_tickets, recipient, benefactor)
  #     @comp.reason = "comment"
  #     @comp.submit
  #   end
    
  #   it "creates an order with a total of zero" do
  #     created_order = Order.find(@comp.order.id)
  #     created_order.total.should eq 0
  #   end
    
  #   it "puts the comp comment on the order" do
  #     @comp.order.should_not be_nil
  #     @comp.order.details.should eq "Comped by: #{benefactor.email} Reason: comment"
  #   end
    
  #   it "marks the items as comped with a realized price a net of zero" do
  #     @comp.order.items.each do |item|
  #       item.realized_price.should eq 0
  #       item.price.should eq 0
  #       item.net.should eq 0
  #       item.state.should eq "comped"
  #     end
  #   end
    
  #   it "marks the tickets as comped and their sold price should be zero" do
  #     @comp.order.items.each do |item|
  #       item.product.sold_price.should eq 0
  #     end
  #   end        
  # end

  # describe "comping valid tickets to a person" do
    
  #   before(:each) do 
  #     selected_tickets = tickets[0..1]
  #     @comp = Comp.new(show, selected_tickets, recipient, benefactor)
  #     @comp.reason = "comment"
  #     @comp.submit
  #   end
    
  #   it "creates an order with a total of zero" do
  #     created_order = Order.find(@comp.order.id)
  #     created_order.total.should eq 0
  #   end
    
  #   it "puts the comp comment on the order" do
  #     @comp.order.should_not be_nil
  #     @comp.order.details.should eq "Comped by: #{benefactor.email} Reason: comment"
  #   end
    
  #   it "marks the items as comped with a realized price a net of zero" do
  #     @comp.order.items.each do |item|
  #       item.realized_price.should eq 0
  #       item.price.should eq 0
  #       item.net.should eq 0
  #       item.state.should eq "comped"
  #     end
  #   end
    
  #   it "marks the tickets as comped and their sold price should be zero" do
  #     @comp.order.items.each do |item|
  #       item.product.sold_price.should eq 0
  #     end
  #   end
  # end
end
