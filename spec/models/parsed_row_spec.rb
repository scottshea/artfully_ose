require 'spec_helper'

describe ParsedRow do

  context "a person with their email and company specified" do
    before do
      @headers = [ "EMAIL", "Company" ]
      @row = [ "test@artful.ly", "Fractured Atlas" ]
      @person = ParsedRow.new(@headers, @row)
    end
  
    it "should have the correct email" do
      @person.email.should == "test@artful.ly"
    end
  
    it "should have the correct company" do
      @person.company.should == "Fractured Atlas"
    end
  
    it "should have a nil name" do
      @person.first.should be_nil
    end
  end
  
  context "a person with tags" do
    before do
      @headers = [ "Tags" ]
      @row = [ "one|two,three four" ]
      @person = ParsedRow.new(@headers, @row)
    end
  
    it "should correctly split on spaces, bars or commas" do
      @person.tags_list.should == %w( one two three-four )
    end
  end

  context "a person with a type" do
    before do
      @headers = [ "Person Type" ]
      @types = [ "individual", "corporation", "FOUNDATION", "GovernMENT", "nonsense", "other" ]
      @people = @types.map { |type| ParsedRow.new(@headers, [type]) }
    end
  
    it "should correctly load the enumerated types" do
      @people.map(&:person_type).should == %w( Individual Corporation Foundation Government Other Other )
    end
  end

  context "a person with do not email" do
    before do
      @headers = [ "Do not email" ]
      @rows = [ true, false ]
      @people = @rows.map { |do_not_email| ParsedRow.new(@headers, [do_not_email]) }
    end

    it "should correctly load do not email" do
      @people.map(&:do_not_email).should == [true, false]
    end
  end
end
