class OrderView < ActiveRecord::Base
  self.table_name = 'order_view'
  self.primary_key = 'id'
  has_many :items, :foreign_key => 'order_id'
  
  default_scope :order => 'created_at DESC'
  scope :before, lambda { |time| where("created_at < ?", time) }
  scope :after,  lambda { |time| where("created_at > ?", time) }
  scope :imported, where("fa_id IS NOT NULL")
  scope :not_imported, where("fa_id IS NULL")
  scope :artfully, where("transaction_id IS NOT NULL")
  
  set_watch_for :created_at, :local_to => :self, :as => :admins
  
  def artfully?
    !transaction_id.nil?
  end
  
  def total
    items.inject(0) {|sum, item| sum + item.price.to_i }
  end

  def has_ticket?
    items.select(&:ticket?).present?
  end

  def has_donation?
    items.select(&:donation?).present?
  end
  
  def time_zone
    "Eastern Time (US & Canada)"
  end
end