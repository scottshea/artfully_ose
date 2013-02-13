class Note < ActiveRecord::Base
  attr_accessible :occurred_at, :text
  
  belongs_to :person
  belongs_to :user
  belongs_to :organization
end

