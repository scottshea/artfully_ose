require 'spec_helper'

describe Statement do
  disconnect_sunspot 
  
  let(:super_code)      { FactoryGirl.create(:discount, :code => "SUPER", :properties => HashWithIndifferentAccess.new( amount: 200 )) }
  let(:other_code)      { FactoryGirl.create(:discount, :code => "OTHER", :properties => HashWithIndifferentAccess.new( amount: 100 )) }
  let(:organization)    { FactoryGirl.create(:organization) } 
  let(:event)           { FactoryGirl.create(:event) }
  let(:paid_chart)      { FactoryGirl.create(:assigned_chart, :event => event) }
  let(:free_chart)      { FactoryGirl.create(:chart_with_free_sections, :event => event) }
  let(:exchangee_show)  { FactoryGirl.create(:show_with_tickets, :organization => organization, :chart => paid_chart, :event => event) }
  let(:paid_show)       { FactoryGirl.create(:show_with_tickets, :organization => organization, :chart => paid_chart, :event => event) }
  let(:free_show)       { FactoryGirl.create(:show_with_tickets, :organization => organization, :chart => free_chart, :event => event) }

  describe "nil show" do
    it "should return an empty @statement if the show is nil" do
      st = Statement.for_show(nil)
      st.should_not be_nil
      st.tickets_sold.should be_nil
    end
  end
  
  describe "free show" do     
  end
  
  describe "no tickets sold" do      
    before(:each) do
      @statement = Statement.for_show(paid_show)
    end
      
    it "should calculate everything correctly" do
      @statement.datetime.should eq paid_show.datetime
      @statement.tickets_sold.should eq 0
      @statement.potential_revenue.should eq 10000
      @statement.tickets_comped.should eq 0
      @statement.gross_revenue.should eq 0
      @statement.processing.should be_within(0.00001).of(0)
      @statement.net_revenue.should eq 0
      
      @statement.cc_net.should eq 0
      @statement.settled.should eq 0
      
      @statement.payment_method_rows.length.should eq 3 

      @statement.discount_rows.length.should eq 0     
    end    
  end
  
  describe "three credit card sales and three comps" do    
    before(:each) do
      setup_discounts
      setup_show
      Settlement.new.tap do |settlement|
        settlement.net = 1000
        settlement.show = paid_show
      end.save
      @statement = Statement.for_show(paid_show)
    end
      
    it "should calculate everything correctly" do
      @statement.datetime.should eq paid_show.datetime
      @statement.tickets_sold.should eq 3
      @statement.potential_revenue.should eq 10000
      @statement.tickets_comped.should eq 3
      @statement.gross_revenue.should eq 2500
      @statement.processing.should be_within(0.00001).of((2500 * 0.035).round)
      @statement.net_revenue.should eq (@statement.gross_revenue - @statement.processing)
      
      @statement.cc_net.should eq 2412
      @statement.settled.should eq 0
      
      @statement.payment_method_rows.length.should eq 3
      
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].should_not be_nil
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].tickets.should eq 3
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].gross.should eq 2500
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].processing.should be_within(0.00001).of((2500 * 0.035).round)
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].net.should eq 2412
      
      @statement.payment_method_rows[::CompPayment.payment_method.downcase].should_not be_nil
      @statement.payment_method_rows[::CompPayment.payment_method.downcase].tickets.should eq 3
      @statement.payment_method_rows[::CompPayment.payment_method.downcase].gross.should eq 0
      @statement.payment_method_rows[::CompPayment.payment_method.downcase].processing.should be_within(0.00001).of(0)
      @statement.payment_method_rows[::CompPayment.payment_method.downcase].net.should eq 0
      
      @statement.payment_method_rows[::CashPayment.payment_method.downcase].should_not be_nil
      @statement.payment_method_rows[::CashPayment.payment_method.downcase].tickets.should eq 0
      @statement.payment_method_rows[::CashPayment.payment_method.downcase].gross.should eq 0
      @statement.payment_method_rows[::CashPayment.payment_method.downcase].processing.should be_within(0.00001).of(0)
      @statement.payment_method_rows[::CashPayment.payment_method.downcase].net.should eq 0
      
      @statement.order_location_rows[::WebOrder.location].should_not be_nil   
      @statement.order_location_rows[::WebOrder.location].tickets.should eq 3 
      
      @statement.order_location_rows[BoxOffice::Order.location].should_not be_nil   
      @statement.order_location_rows[BoxOffice::Order.location].tickets.should eq 0 
      
      @statement.order_location_rows[CompOrder.location].should_not be_nil   
      @statement.order_location_rows[CompOrder.location].tickets.should eq 3

      @statement.discount_rows.length.should eq 2
      @statement.discount_rows[super_code.code].tickets.should eq 2
      @statement.discount_rows[super_code.code].discount.should eq 400

      @statement.discount_rows[other_code.code].tickets.should eq 1
      @statement.discount_rows[other_code.code].discount.should eq 100
    end
  end
  
  describe "with an imported show" do      
    before(:each) do
      setup_show
      setup_exchange
    end
      
    it "should not show a cc_net for imported events" do
      paid_show.event.stub(:imported?).and_return(true)
      @statement = Statement.for_show(paid_show, true)
      @statement.cc_net.should eq 0
    end  
  end
  
  describe "with an exchange" do      
    before(:each) do
      setup_show
      setup_exchange
      @statement = Statement.for_show(paid_show)
    end
      
    it "should calculate everything correctly" do
      @statement.datetime.should eq paid_show.datetime
      @statement.tickets_sold.should eq 4
      @statement.potential_revenue.should eq 10000
      @statement.tickets_comped.should eq 3
      @statement.gross_revenue.should eq 4000
      @statement.processing.should be_within(0.00001).of(4000 * 0.035)
      @statement.net_revenue.should eq (@statement.gross_revenue - @statement.processing)
      
      @statement.cc_net.should eq 3860
      
      @statement.payment_method_rows.length.should eq 3
      
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].should_not be_nil
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].tickets.should eq 4
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].gross.should eq 4000
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].processing.should be_within(0.00001).of(4000 * 0.035)
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].net.should eq 3860
      
    end  
  end
  
  describe "with a refund" do      
    before(:each) do
      setup_show
      setup_refund
      @statement = Statement.for_show(paid_show.reload)
    end
      
    it "should calculate everything correctly" do
      @statement.datetime.should eq paid_show.datetime
      
      @statement.tickets_sold.should eq 2
      @statement.potential_revenue.should eq 10000
      @statement.tickets_comped.should eq 3
      @statement.gross_revenue.should eq 2000
      @statement.processing.should be_within(0.00001).of(2000 * 0.035)
      @statement.net_revenue.should eq (@statement.gross_revenue - @statement.processing)
      
      @statement.cc_net.should eq 1930
      
      @statement.payment_method_rows.length.should eq 3
      
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].should_not be_nil
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].tickets.should eq 2
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].gross.should eq 2000
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].processing.should be_within(0.00001).of(2000 * 0.035)
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].net.should eq 1930
      
    end  
  end
  
  def setup_discounts
    paid_show.tickets[0].discount = super_code
    paid_show.tickets[0].sold_price = paid_show.tickets[0].price - super_code.properties[:amount]
    paid_show.tickets[0].save
    paid_show.tickets[1].discount = super_code
    paid_show.tickets[1].sold_price = paid_show.tickets[1].price - super_code.properties[:amount]
    paid_show.tickets[1].save
    paid_show.tickets[2].discount = other_code
    paid_show.tickets[2].sold_price = paid_show.tickets[2].price - other_code.properties[:amount]
    paid_show.tickets[2].save
  end

  def setup_show
    @orders = []

    0.upto(2) do |i|
      (paid_show.tickets[i]).sell_to(FactoryGirl.create(:person))
      order = FactoryGirl.create(:credit_card_order, :organization => organization)
      order << paid_show.tickets[i]
      order.save
      @orders << order
    end
    
    Comp.new(paid_show, paid_show.tickets[3..5], FactoryGirl.create(:person), FactoryGirl.create(:user_in_organization)).submit
    
    paid_show.tickets.reload
  end
  
  def setup_exchange
    (exchangee_show.tickets[0]).sell_to(FactoryGirl.create(:person))
    order = FactoryGirl.create(:credit_card_order, :organization => organization, :service_fee => 400)
    order << exchangee_show.tickets[0]
    order.save
    order.reload
      
    exchange = Exchange.new(order, Array.wrap(order.items.first), Array.wrap(paid_show.tickets[6]))
    exchange.submit
  end
  
  def setup_refund
    gateway = ActiveMerchant::Billing::BraintreeGateway.new(
        :merchant_id => Rails.application.config.braintree.merchant_id,
        :public_key  => Rails.application.config.braintree.public_key,
        :private_key => Rails.application.config.braintree.private_key
      )    
  
    successful_response = ActiveMerchant::Billing::Response.new(true, 'nice job!', {}, {:authorization => '3e4r5q'} )
    gateway.stub(:refund).and_return(successful_response)
    ActiveMerchant::Billing::BraintreeGateway.stub(:new).and_return(gateway)
    
    refund = Refund.new(@orders.first, @orders.first.items)
    refund.submit({:and_return => true})
  end
end