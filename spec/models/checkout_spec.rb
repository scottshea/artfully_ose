require 'spec_helper'

describe Checkout do
  disconnect_sunspot
  let(:payment) { FactoryGirl.build(:credit_card_payment, :customer => FactoryGirl.build(:person)) }
  let(:order) { FactoryGirl.build(:cart) }
  
  subject { Checkout.new(order, payment) }
  
  it "should set the amount for the payment from the order" do
    subject.payment.amount.should eq order.total
  end
  
  describe "#valid?" do
    
    #This happens if the tickets expired while they're entering payment information
    it "should not be valid without tickets" do
      subject = Checkout.new(FactoryGirl.build(:cart), payment)
      subject.should_not be_valid
      subject.error.should eq "Your tickets have expired.  Please select your tickets again."
    end
    
    it "should not be valid without a payment if the order total > 0 (Not Free)" do
      subject = Checkout.new(FactoryGirl.create(:cart_with_items), payment)
      subject.payment = nil
      subject.should_not be_valid
    end
      
    it "should not be valid without an email address on the customer" do
      [nil, "", " "].each do |invalid_email|    
        payment.customer.email = invalid_email
        invalid_checkout = Checkout.new(order, payment)
        invalid_checkout.should_not be_valid
      end
    end

    it "should be valid without a payment if the cart total is 0 (Free)" do
      subject = Checkout.new(FactoryGirl.create(:cart_with_free_items), payment)
      subject.payment.credit_card = nil
      subject.should be_valid
    end
  
    it "should not be valid without an cart" do
      subject.cart = nil
      subject.should_not be_valid
    end
    
    it "should not be valid if the payment is invalid and cart total > 0 (Not Free)" do
      subject = Checkout.new(FactoryGirl.build(:cart_with_items), payment)
      subject.payment.stub(:valid?).and_return(false)
      subject.should_not be_valid
    end
    
    it "should not be valid if the payment is invalid but the cart total is 0 (Free)" do
      subject.payment.stub(:valid?).and_return(false)
      subject.should_not be_valid
    end
  end

  describe "cash payments" do
    let(:payment)         { CashPayment.new(FactoryGirl.create(:person)) }
    let(:cart_with_item)  { FactoryGirl.build(:cart_with_items) }
    subject               { BoxOffice::Checkout.new(cart_with_item, payment) }
  
    it "should always approve orders with cash payments" do
      subject.stub(:create_order).and_return(Array.wrap(BoxOffice::Order.new))
      Person.stub(:find_or_create).and_return(FactoryGirl.build(:person))
      subject.cart.stub(:organizations).and_return(Array.wrap(FactoryGirl.build(:person).organization))
      subject.finish.should be_true
    end
  end
  
  describe "#finish" do
    before(:each) do
      subject.cart.stub(:pay_with)
      subject.cart.stub(:approved?).and_return(true)
    end

    # # TODO: Fix these specs!
    # describe "people without emails" do
    #   it "should receive an email for dummy records" do
    #     OrderMailer.should_not_receive(:confirmation_for)
    #     Person.stub(:find_or_create).and_return(FactoryGirl.build(:dummy))
    #     subject.cart.stub(:organizations).and_return([FactoryGirl.build(:dummy).organization])
    #     subject.cart.stub(:approved?).and_return(true)
    #     subject.finish.should be_true
    #   end
  
    #   it "should receive an email if we don't have an email address for the buyer" do
    #     OrderMailer.should_not_receive(:confirmation_for)
    #     Person.stub(:find_or_create).and_return(FactoryGirl.build(:person_without_email))
    #     subject.cart.stub(:organizations).and_return([FactoryGirl.build(:person_without_email).organization])
    #     subject.cart.stub(:approved?).and_return(true)
    #     subject.finish.should be_true
    #   end
    # end
    
    # describe "order creation" do  
    #   organization = FactoryGirl.build(:organization)
      
    #   before(:each) do    
    #     person = FactoryGirl.build(:person, :organization => organization)
    #     Person.stub(:find_or_create).and_return(person)
    #     subject.cart.stub(:approved?).and_return(true)
    #     subject.cart.stub(:organizations).and_return(Array.wrap(organization))
    #     subject.cart.stub(:organizations_from_tickets).and_return(Array.wrap(organization))
    #   end
    
    #   it "should put special instructions on the order" do
    #     special_instructions = "Bring me a fifth of Glengoole Black and a bag of gummi bears"
    #     subject.cart.should_receive(:special_instructions).and_return(special_instructions)
    #     subject.finish.should be_true
    #     order = organization.orders.first
    #     order.should_not be_nil
    #     order.special_instructions.should eq special_instructions
    #   end
    # end

    describe "return value" do
      before(:each) do
        Person.stub(:find_or_create).and_return(FactoryGirl.build(:person))
        subject.cart.stub(:organizations).and_return(Array.wrap(FactoryGirl.build(:person).organization))
      end
      # # TODO: Fix this spec!
      # it "returns true if the order was approved" do
      #   subject.cart.stub(:approved?).and_return(true)
      #   subject.finish.should be_true
      # end
  
      it "returns false if the order is not approved" do
        subject.cart.stub(:approved?).and_return(false)
        subject.finish.should be_false
      end
    end
  
    describe "people creation" do
  
      let(:email){ payment.customer.email }
      let(:organization){ FactoryGirl.create(:organization) }
      let(:attributes){
        { :email           => email,
          :organization_id => organization.id,
          :first_name      => payment.customer.first_name,
          :last_name       => payment.customer.last_name
        }
      }
      
      let(:person) { FactoryGirl.create(:person, attributes) }
  
      it "should add the phone number to the person" do      
        Delayed::Worker.delay_jobs = false
        subject.cart.stub(:organizations_from_tickets).and_return(Array.wrap(organization))
        subject.cart.stub(:organizations).and_return(Array.wrap(organization))
        Person.should_receive(:find_by_email_and_organization).with(email, organization).and_return(person)
        Person.should_not_receive(:create)
        payment.should_receive(:payment_phone_number).and_return("310-310-3101")
        person.should_receive(:add_phone_if_missing).with("310-310-3101")
        subject.finish
        Delayed::Worker.delay_jobs = true
      end
      
      it "should create a person record when finishing with a new customer" do
        subject.cart.stub(:organizations_from_tickets).and_return(Array.wrap(organization))
        subject.cart.stub(:organizations).and_return(Array.wrap(organization))
        Person.should_receive(:find_by_email_and_organization).with(email, organization).and_return(nil)
        Person.should_receive(:create).with(attributes).and_return(person)
        subject.finish
      end
  
      it "should not create a person record when the person already exists" do
        subject.cart.stub(:organizations_from_tickets).and_return(Array.wrap(organization))
        subject.cart.stub(:organizations).and_return(Array.wrap(organization))
        Person.should_receive(:find_by_email_and_organization).with(email, organization).and_return(person)
        Person.should_not_receive(:create)
        subject.finish
      end
    end
  end
end
