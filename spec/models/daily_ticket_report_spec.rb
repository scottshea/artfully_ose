require 'spec_helper'

describe DailyTicketReport do
  disconnect_sunspot
  let(:org) { FactoryGirl.create(:organization) }
  let(:order) { FactoryGirl.create(:order, organization: org, created_at: 1.day.ago)}
  let(:imported_order) { FactoryGirl.create(:imported_order, organization: org, created_at: 1.day.ago)}
  let(:donation) { FactoryGirl.create(:donation, organization: org, amount: 1000)}
  let(:ticket) { FactoryGirl.create(:ticket, organization: org)}
  let(:ticket_2) { FactoryGirl.create(:ticket, organization: org)}
  let(:report) { DailyTicketReport.new(org) }

  describe "#rows" do
    subject { report.rows }
    before(:each) do
      order << ticket
      imported_order << ticket_2
    end
    it "should not have imported rows from orders" do
      subject.length.should == 1
    end
  end

  describe "#total" do
    subject { report.total }
    context "with only a donation of $10.00" do
      before { order << donation }
      it { should == "$0.00" }
    end

    context "with only a ticket" do
      before { order << ticket }
      it { should == "$50.00" }
    end

    context "with a ticket and a donation" do
      before do
        order << ticket
        order << donation
      end
      it { should == "$50.00" }
    end
  end

  describe "#header" do
    subject { report.header }
    it { should == ["Order ID", "Total", "Customer", "Details", "Special Instructions"] }
  end

  describe "#to_table" do
    subject {report.to_table }
    context "with a ticket" do
      before { order << ticket }
      it "should look like this array" do
        subject.should == [
          ["Order ID", "Total", "Customer", "Details", "Special Instructions"],
          [order.id, report.total, order.person, order.ticket_details, order.special_instructions],
          ["Total:", report.total, "", "", ""]
        ]
      end
    end
  end

  describe "#footer" do
    subject { report.footer }
    it { should == ["Total:", report.total, "", "", ""] }
  end

  describe "Row" do
    before do
      order << ticket
      order << donation
    end
    describe "#ticket_details" do
      subject { report.rows.first.ticket_details }
      it { should == order.ticket_details }
    end
    describe "#total" do
      subject { report.rows.first.total }
      it { should == "$50.00" }
    end
    describe "#person" do
      subject { report.rows.first.person }
      it { should == order.person }
    end
    describe "#person_id" do
      subject { report.rows.first.person_id }
      it { should == order.person.id }
    end
    describe "#special_instructions" do
      subject { report.rows.first.special_instructions }
      it { should == order.special_instructions }
    end
  end
end