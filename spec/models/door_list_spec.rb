require 'spec_helper'

describe DoorList do
  disconnect_sunspot  
  let(:show)                  { FactoryGirl.create(:show_with_tickets) }
  let(:buyer)                 { FactoryGirl.create(:person) }
  let(:buyer_without_email)   { FactoryGirl.create(:person_without_email) }
  let(:special_instructions)  { "Seriously, that's like Eggs 101, Woodhouse." }

  # TODO: Fix these specs! Almost none of them are working. Change build to create?
  # describe "items" do
    
  #   before(:each) do
  #     items = []      
  #     show.tickets[0..5].each do |t|
  #       t.stub(:special_instructions).and_return(special_instructions)
  #     end   
  #     show.tickets[0..2].each { |t| t.sell_to buyer }
  #     show.tickets[3..4].each { |t| t.sell_to buyer_without_email }
  #     @door_list = DoorList.new(show)
  #   end
    
  #   describe "buyers without emails" do  
  #     it "should work for buyers who have no email address" do
  #       @door_list.should have(5).items
  #     end
  #   end
  
  #   describe "buyers with emails" do
  #     it "should save a reference to the show for which it was created" do
  #       @door_list.show.should eq show
  #     end
  
  #     it "should return an array of Buyers and their tickets" do
  #       list = @door_list.items
  #       list.each do |item|
  #         item.buyer.should eq item.ticket.buyer
  #         show.tickets.should include item.ticket
  #       end
  #     end
  #   end
  # end

  # describe "items" do
  #   let(:special_instructions) { "Seriously, that's like Eggs 101, Woodhouse." }
  #   let(:order) { FactoryGirl.build(:order, :person => buyer, :special_instructions => special_instructions) }

  #   subject { DoorList.new show }
    
  #   before(:each) do
  #     tickets = 5.times.collect { FactoryGirl.build(:ticket, :state => :sold, :show => show, :buyer => buyer)}
  #     items = []
  #     tickets.each { |t| items << FactoryGirl.build(:item, :product => t, :order => order)}

  #     subject.show.reload
  #   end
    
  #   describe "buyers without emails" do  
  #     before(:each) do
  #       (0..2).each do |t|
  #         show.tickets[t].stub(:buyer).and_return(buyer_without_email)
  #       end
  #       (3..4).each do |t|
  #         show.tickets[t].stub(:buyer).and_return(buyer)
  #       end
  #     end
    
  #     it "should work for buyers who have no email address" do
  #       subject.should have(5).items
  #     end
  #   end
  
  #   describe "buyers with emails" do
  #     it "should save a reference to the show for which it was created" do
  #       subject.show.should eq show
  #     end
  
  #     it "should return an array of Buyers and their tickets" do
  #       list = subject.items
  #       list.each do |item|
  #         item.buyer.should eq buyer
  #         show.tickets.should include item.ticket
  #       end
  #     end
  #   end
  
  #   describe "special instructions" do
  #     it "should be included when they are present on the order" do
  #       subject.items.each do |item|
  #         item.special_instructions.should eq special_instructions
  #       end  
  #     end
  #   end
  # end
end
