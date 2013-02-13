require 'spec_helper'

describe Venue do
  describe "#geocode_address" do
    it "should return the full address" do
      venue = Venue.new(:address1 => "Line 1", :address2 => "Line 2", :city => "City", :state => "State", :zip => "Zipcode")
      venue.geocode_address.should == "Line 1, Line 2, City, State Zipcode"
    end
  end
end
