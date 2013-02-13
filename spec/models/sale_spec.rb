require 'spec_helper'

describe Sale do
  disconnect_sunspot
  let(:show){FactoryGirl.build(:show)}
  let(:chart){FactoryGirl.create(:chart_with_sections)}
  let(:quantities) { {chart.sections.first.id.to_s => "2"} }

  subject { Sale.new(show, chart.sections, quantities) }

  describe "non_zero_quantities" do
    let(:quantities) {{chart.sections.first.id.to_s => "0"}}
      
    it "should tell me if they selected any tickets" do
      @empty_sale = Sale.new(show, chart.sections, quantities)
      @empty_sale.non_zero_quantities?.should be_false
    end
  end

  describe "load tickets" do
    before(:each) do
      tix = Array.new(2)
      tix.collect! { FactoryGirl.build(:ticket, :section => chart.sections.first)}
      Ticket.stub(:available).and_return(tix)
    end
    
    it "loads available tickets from a hash of sections" do
      # load_tickets is called in the sale.rb initializer
      subject.tickets.length.should eq 2
    end
  end

  describe "#sell" do
    let(:order) { mock(:order, :items => []) }
    
    let(:compee) { FactoryGirl.build(:person) }
  
    let(:payment) { mock(:cash_payment, 
                         :customer => FactoryGirl.build(:person_with_address, :with_id), 
                         :amount= => nil, 
                         :requires_settlement? => false) }
  
    let(:comp_payment) { CompPayment.new({:benefactor => FactoryGirl.create(:user), :customer => FactoryGirl.create(:person)}) }
                         
    let(:checkout) { mock(:checkout, :order => order)}
    
    before(:each) do
      tix = Array.new(2)
      tix.collect! { FactoryGirl.build(:ticket, :section => chart.sections.first)}
      Ticket.stub(:available).and_return(tix)
    end
       
    it "should recover if CC processing is unavailable" do
      BoxOffice::Checkout.should_receive(:new).and_return(checkout)
      checkout.should_receive(:finish).and_raise(Errno::ECONNREFUSED)
      checkout.should_not_receive(:person)
      subject.sell(payment)
      subject.errors.should_not be_empty
      subject.sale_made.should be_false
    end
    
    it "should recover and throw an error is something unexpected happens" do
      BoxOffice::Checkout.should_receive(:new).and_return(checkout)
      checkout.should_receive(:finish).and_raise(Exception)
      checkout.should_not_receive(:person)
      subject.sell(payment)
      subject.errors.should_not be_empty
      subject.sale_made.should be_false
    end
       
    it "should comp tickets" do
      BoxOffice::Checkout.should_not_receive(:new)
      c = Comp.new(subject.tickets.first.show, subject.tickets, comp_payment.customer, comp_payment.benefactor)
      Comp.should_receive(:new).with(subject.tickets.first.show, subject.tickets, comp_payment.customer, comp_payment.benefactor).and_return(c)
      c.should_receive(:submit)
      subject.sell(comp_payment)
    end
        
    it "creates a new BoxOffice::Checkout and a new BoxOfficeCart" do
      BoxOffice::Checkout.should_receive(:new).and_return(checkout)
      checkout.should_receive(:finish).and_return(true)
      checkout.should_receive(:person).and_return(FactoryGirl.build(:person))
      subject.cart.tickets.size.should eq 2
      subject.sell(payment)
      subject.cart.tickets.size.should eq 2
      subject.sale_made.should be_true
    end
  end
end
