class GatewayTransaction < ActiveRecord::Base
  include AdminTimeZone
  has_one :order, :primary_key => :transaction_id, :foreign_key => :transaction_id
  has_many :items, :through => :order
  serialize :response
  
  set_watch_for :created_at, :local_to => :self, :as => :admins

  before_create :clean

  def clean
    unless self.response.params.fetch("braintree_transaction",{}).fetch("credit_card_details", {}).fetch("masked_number", nil).nil?
      self.response.params["braintree_transaction"]["credit_card_details"]["masked_number"] = nil
      self.response.params["braintree_transaction"]["credit_card_details"]["bin"] = nil
    end
  end
end