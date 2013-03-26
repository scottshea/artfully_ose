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
    Action.includes(:person).where(:organization_id => organization).order('occurred_at DESC').limit(limit)
  end

  def give_action_subtypes
    GIVE_TYPES
  end

  #
  # This exists solely so that DJ can serialize an unsaved action so that ActionJob can run
  # There's nothing inherent to Action in this method so it looks like a good candidate to 
  # move into a Module.  But, I'm not thrilled with it and don't want it used willy-nilly
  # Perhaps in an DelayedJob::Unsaved::Serializable Module or something. 
  #
  def to_open_struct
    action_struct = OpenStruct.new
    self.class.column_names.each do |col|
      action_struct.send("#{col}=", self.send(col))
    end
    action_struct
  end

  def self.from_open_struct(action_struct)
    action = Kernel.const_get(action_struct.type).new
    Kernel.const_get(action_struct.type).column_names.each do |col|
      action.send("#{col}=", action_struct.send(col)) unless action_struct.send(col).nil?
    end
    action    
  end
end
