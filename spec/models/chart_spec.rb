require 'spec_helper'

describe Chart do
  subject { FactoryGirl.build(:chart) }

  it { should respond_to :name }
  it { should respond_to :is_template }
  it { should respond_to :event_id }
  it { should respond_to :organization_id }

  describe "#valid?" do
    it { should be_valid }

    it "is not be valid without a name" do
      subject.name = nil
      subject.should_not be_valid

      subject.name = ""
      subject.should_not be_valid
    end
  end

  describe "updating a chart" do
    it "should allow for a totally blank chart to be submitted" do
      params_hash = nil
      subject.update_attributes_from_params(params_hash)
    end
  end

  describe "upgrading the event" do
    it "should update the event from free to paid if a paid section has been added to a free event" do
      @chart = FactoryGirl.build(:chart)
      @chart.event = FactoryGirl.build(:free_event)
      @chart.event.should be_free
      @chart.sections << Section.new({:price => 30, :name => 'one', :capacity => 30})
      @chart.upgrade_event
      @chart.event.should_not be_free
    end
    
    it "should not update the event if the event is nil" do
      @chart = FactoryGirl.build(:chart)
      @chart.event = nil
      @chart.upgrade_event
    end
    
    it "should not update the event when all free sections" do
      @chart = FactoryGirl.build(:chart)
      @chart.event = FactoryGirl.build(:free_event)
      @chart.event.should be_free
      @chart.sections << Section.new({:price => 0, :name => 'one', :capacity => 30})
      @chart.upgrade_event
      @chart.event.should_not_receive(:is_free)
      @chart.event.should be_free
    end
  end

  it "should always order sections by price descending" do
    @chart = FactoryGirl.build(:chart)
    @chart.name = 'Chartie'
    @chart.sections << Section.new({:price => 30, :name => 'one', :capacity => 30})
    @chart.sections << Section.new({:price => 40, :name => 'two', :capacity => 30})
    @chart.sections << Section.new({:price => 25, :name => 'three', :capacity => 30})
    @chart.save
    @chart = Chart.find(@chart.id)
    
    @chart.sections[0].price.should eq 40
    @chart.sections[1].price.should eq 30
    @chart.sections[2].price.should eq 25
  end
  
  it "creates a default based on an event" do
    @event = FactoryGirl.build(:event)
    @chart = Chart.default_chart_for(@event)
  
    @chart.name.should eq Chart.get_default_name(@event.name)
    @chart.event_id.should eq @event.id
    @chart.id.should eq nil
  end
  
  describe "#as_json" do
    it "includes the sections in the output" do
      subject.sections << FactoryGirl.create(:section, :chart => subject)
      subject.as_json[:sections].should_not be_empty
    end
  end
  
  describe "#copy!" do
    before(:each) do
      subject.sections = 2.times.collect { FactoryGirl.build(:section) }
      subject.save!
    end
  
    let(:copy) { subject.copy! }
  
    it "does not have the same id as the original" do
      copy.id.should_not eq subject.id
    end
  
    it "has the same name as the original" do
      copy.name.should eq "#{subject.name} (Copy)"
    end
  
    it "has the same organization" do
      copy.organization_id.should eq subject.organization_id
    end
  end
  
  describe "#dup!" do
    before(:each) do
      subject.sections = 2.times.collect { FactoryGirl.build(:section) }
      subject.save!
    end
  
    let(:copy) { subject.dup! }
  
    it "does not have the same id as the original" do
      copy.id.should_not eq subject.id
    end
  
    it "has the same name as the original" do
      copy.name.should eq subject.name
    end
  
    it "has the same organization" do
      copy.organization_id.should eq subject.organization_id
    end
  
    describe "and sections" do
      it "has the same number of sections as the original" do
        copy.sections.size.should eq subject.sections.size
      end
  
      it "copies each sections name" do
        copy.sections.collect { |section| section.name }.should eq subject.sections.collect { |section| section.name }
      end
  
      it "copies each sections price" do
        copy.sections.collect { |section| section.price }.should eq subject.sections.collect { |section| section.price }
      end
  
      it "copies each sections capacity" do
        copy.sections.collect { |section| section.capacity }.should eq subject.sections.collect { |section| section.capacity }
      end
  
      it "copies each sections description" do
        copy.sections.collect { |section| section.description }.should eq subject.sections.collect { |section| section.description }
      end
    end
  end
end
