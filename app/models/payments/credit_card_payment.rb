class CreditCardPayment < ::Payment
  payment_method [:credit_card, :credit_card_swipe, :credit_card_manual, :cc, :credit]
  
  #ActiveMerchant::Billing::CreditCard
  attr_accessor :credit_card 
  
  def initialize(params = {})
    self.credit_card    ||= ActiveMerchant::Billing::CreditCard.new
    self.customer       ||= Person.new
    build(params) unless params.blank?
  end
  
  def per_item_processing_charge
    lambda { |item| item.realized_price * 0.035 }
  end
  
  def payment_phone_number
    self.customer.phones.first.try(:number)
  end
  
  #
  # We may be able to get some milage out of a repo called active_attr: https://github.com/cgriego/active_attr
  #
  def build(params)
    [:amount, :user_agreement, :transaction_id].each do |field| 
      self.instance_variable_set("@#{field.to_s}", params[field])
    end
    
    unless params[:credit_card].nil?
      params[:credit_card].each do |key, value| 
        self.credit_card.send("#{key}=", value)
      end
    end
    
    unless params[:customer].nil?
      self.customer.first_name  = params[:customer][:first_name]
      self.customer.last_name   = params[:customer][:last_name]
      self.customer.email       = params[:customer][:email]
      
      self.customer.phones      << Phone.new(:number => params[:customer][:phone]) unless params[:customer][:phone].blank?
      
      self.customer.address = Address.new(:address1 => params[:customer][:address][:address1],
                                          :city     => params[:customer][:address][:city],
                                          :state    => params[:customer][:address][:state],
                                          :zip      => params[:customer][:address][:zip])
    end
  end
  
  def gateway
    @gateway ||= ActiveMerchant::Billing::BraintreeGateway.new(
        :merchant_id => Rails.configuration.braintree.merchant_id,
        :public_key  => Rails.configuration.braintree.public_key,
        :private_key => Rails.configuration.braintree.private_key
      )
  end
  
  def requires_authorization?
    amount > 0
  end

  def requires_settlement?
    true
  end

  #
  # refund_amount: The total amount of money to be sent to the patron
  # transaction_id: The transaction_id of the original transaction
  # options:
  #   :service_fee: The service fees being refunded.  This is for record keeping *only*  It WILL NOT be added to refund_amount
  #
  def refund(refund_amount, transaction_id, options = {})
    return true if (refund_amount <= 0)
    response = gateway.refund(refund_amount, transaction_id)
    record_gateway_transaction((options[:service_fee] * -1), (refund_amount * -1), response)
    self.transaction_id = response.authorization
    self.errors.add(:base, response.message) unless response.message.blank?
    response.success?
  end
  
  #purchase submits for auth and passes a flag to merchant to settle immediately
  def purchase(options={})
    response = gateway.purchase(self.amount, credit_card, options.except(:service_fee))
    record_gateway_transaction(options[:service_fee], self.amount, response)
    self.transaction_id = response.authorization
    self.errors.add(:base, BRAINTREE_REJECT_MESSAGE_MAPPING[response.message]) unless response.message.blank?
    response.success?
    
    rescue Errno::ECONNREFUSED => e
      ::Rails.logger.error "Connection to processor refused"
      self.errors.add(:base, "We had a problem processing the sale, please check all your information and try again.")
      false
    rescue Exception => e
      ::Rails.logger.error "Could not contact processor"
      ::Rails.logger.error e
      ::Rails.logger.error e.backtrace
      self.errors.add(:base, "We had a problem processing the sale, please check all your information and try again.")
      false
  end
  
  def authorize(options={})
    response = gateway.authorize(self.amount, credit_card, options)
    self.transaction_id = response.authorization
    response.authorization
  end
  
  def capture(authorization, options={})
    gateway.capture(self.amount, authorization, options)
  end
  alias :settle :capture

  #
  # This can't be delayed_job'd because DJ can't deserialize ARs that haven't been persisted
  #
  def record_gateway_transaction(service_fee, amount, response)
    begin 
      attrs = {}
      attrs[:transaction_id] = response.authorization
      attrs[:success]        = response.success?
      attrs[:service_fee]    = service_fee
      attrs[:amount]         = amount
      attrs[:message]        = response.message
      attrs[:response]       = response
      @gateway_transaction = GatewayTransaction.create(attrs)
    rescue Exception => e
      ::Exceptional.context(:gateway_transaction => @gateway_transaction)
      ::Exceptional.handle(e, "Failed to persist Gateway Transaction")
    end
  end
end