class CashPayment < Payment
  payment_method :cash
  attr_accessor :amount

  def initialize(params = {})
    self.customer = params[:customer]
  end

  def requires_authorization?
    false
  end

  def requires_settlement?
    false
  end
  
  def per_item_processing_charge
    lambda { |item| 0 }
  end
  
  def transaction_id
    nil
  end
end