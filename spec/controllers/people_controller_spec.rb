require 'spec_helper'

describe PeopleController do
  disconnect_sunspot
  login_user

  before(:each) do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
    @controller.stub!(:current_ability).and_return(@ability)
  end

  describe "json search results" do
    let(:sample_person) { FactoryGirl.create(:person) }

    it "should return search results in json form" do
      @ability.can :manage, Person
      Person.should_receive(:search_index).and_return([sample_person])
      get :index, :format => "json", :search => sample_person.first_name, :commit => "Search"
      response.body.should be_json_eql([
        {
            "company_name" => nil,
            "created_at" => sample_person.created_at,
            "deleted_at" => nil,
            "do_not_email" => false,
            "dummy" => false,
            "email" => sample_person.email,
            "facebook_url" => nil,
            "first_name" => sample_person.first_name,
            "id" => 1,
            "import_id" => nil,
            "last_name" => sample_person.last_name,
            "lifetime_donations" => 0,
            "lifetime_value" => 0,
            "linked_in_url" => nil,
            "organization_id" => sample_person.organization.id,
            "person_type" => nil,
            "salutation" => nil,
            "state" => nil,
            "subscribed_lists" => [],
            "title" => nil,
            "twitter_handle" => nil,
            "updated_at" => sample_person.updated_at,
            "website" => nil
        }
      ].to_json)
    end
  end
end