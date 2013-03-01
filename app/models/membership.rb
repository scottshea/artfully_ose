class Membership < ActiveRecord::Base
  
  # Be careful here!  :user needs to come out of this if we ever support update action on memberships controller
  attr_accessible :user
  
  belongs_to :user
  belongs_to :organization

  validates :user_id, :uniqueness => {:scope => :organization_id}
end