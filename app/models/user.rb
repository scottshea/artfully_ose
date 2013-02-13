  class User < ActiveRecord::Base

  include Ext::DeviseConfiguration
  include Ext::Integrations::User

  has_many :shows
  has_many :orders
  has_many :imports
  has_many :discounts

  has_many :memberships
  has_many :organizations, :through => :memberships

  scope :logged_in_more_than_once, where("users.sign_in_count > 1")

  def self.generate_password
    Devise.friendly_token
  end

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :user_agreement, :newsletter_emails

  def is_in_organization?
    @is_in_organization ||= memberships.any?
  end

  def current_organization
    @current_organization ||= (is_in_organization? ? memberships.first.organization : Organization.new)
  end

  def membership_in(organization)
    memberships.where(:organization_id => organization.id).limit(1).first
  end
  
  def self.like(query = "")
    return if query.blank?
    q = "%#{query}%"
    self.joins("LEFT OUTER JOIN memberships m ON m.user_id = users.id")
        .joins("LEFT OUTER JOIN organizations o ON o.id = m.organization_id")
        .includes(:organizations)
        .where("users.email like ? or o.name like ?", q, q)
  end

  def active_for_authentication?
    super && !suspended?
  end
end
