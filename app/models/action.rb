class Action < ActiveRecord::Base
  include OhNoes::Destroy
  
  belongs_to :person
  belongs_to :creator, :class_name => "User", :foreign_key => "creator_id"
  belongs_to :organization
  belongs_to :subject, :polymorphic => true
  belongs_to :import

  validates_presence_of :occurred_at
  validates_presence_of :person_id

  set_watch_for :occurred_at, :local_to => :organization

  #
  # Action types: give, go, do, get, join, hear
  #
  GIVE_TYPES = [ "Monetary", "In-Kind" ].freeze

  def self.create_of_type(type)
    case type
      when "hear" then HearAction.new
      when "give" then GiveAction.new
    end
  end

  def set_params(params, person)
    params ||= {}

    self.occurred_at = params[:occurred_at]
    self.subtype = params[:subtype]
    self.details = params[:details]

    self.person = person
    self.subject = person
  end

  def set_creator(user)
    self.creator_id = user.id
    self.organization_id = user.current_organization.id
  end

  def unstarred?
    !starred?
  end
  
  def verb
    ""
  end
  
  def sentence
    (verb + " " + details.uncapitalize)
  end
  
  def full_details
    details
  end

  def hear_action_subtypes
    [ "Email (sent)",
      "Email (received)",
      "Phone (initiated)",
      "Phone (received)",
      "Postal (sent)",
      "Postal (received)",
      "Meeting",
      "Twitter",
      "Facebook",
      "Blog",
      "Press" ]
  end
  
  #This returnes an ARel, so you can chain
  def self.recent(organization, limit = 5)
    Action.includes(:person).where(:organization_id => organization).order('created_at DESC').limit(limit)
  end

  def give_action_subtypes
    GIVE_TYPES
  end
end
