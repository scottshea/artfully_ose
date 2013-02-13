require 'spec_helper'

describe Phone do
  describe "importing from Athena" do
    it "should parse the phone" do
      p = Phone.from_athena("Work:4444444444")
      p.kind.should eq "Work"
      p.number.should eq "4444444444"
    end
    
    it "should parse the phone without a number" do
      p = Phone.from_athena("Work:")
      p.kind.should eq "Work"
      p.number.should be_nil
    end
  end
end