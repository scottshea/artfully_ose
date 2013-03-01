class Refund
  include Adjustments
  attr_accessor :order, :refund_order, :items, :message

  BRAINTREE_UNSETTLED_MESSAGE = "Cannot refund a transaction unless it is settled. (91506)"
  FRIENDLY_UNSETTLED_MESSAGE = "The processor cannot refund that transaction yet. Please try again in a few hours."

  def initialize(order, items)
    self.order = order
    self.items = items
  end

  def submit(options = {})
    return_items_to_inventory = options[:and_return] || false

    items.each do |i|
      unless i.refundable?
        @message = "Those items have already been refunded."
        return
      end
    end

    @payment = Payment.create(@order.payment_method)
    @success = @payment.refund(refund_amount, order.transaction_id, options.merge({:service_fee => service_fee}))
    @message = format_message(@payment)
    
    if @success
      items.each { |i| i.return!(return_items_to_inventory) }
      items.each(&:refund!)
      create_refund_order(@payment.transaction_id)
    end
  end

  def successful?
    @success || false
  end

  #This is brittle, sure, but active merchant doens't pass along any processor codes so we have to match the whole stupid string
  def format_message(payment)
    unless payment.errors.empty?
      (payment.errors[:base].first.eql? BRAINTREE_UNSETTLED_MESSAGE) ? FRIENDLY_UNSETTLED_MESSAGE : payment.errors.full_messages.to_sentence
    end
  end

  #
  # The gross amount of the refund.  This is the total amount of money we are returning to the patron
  #
  def refund_amount
    item_total + service_fee
  end

  def service_fee
    (number_of_non_free_items(items) * service_fee_per_item(order.items))
  end

  private
  
    def item_total
      items.collect(&:price).sum
    end
  
    def create_refund_order(transaction_id = nil)
      @refund_order = RefundOrder.new
      @refund_order.person = order.person
      @refund_order.transaction_id = transaction_id
      @refund_order.payment_method = order.payment_method
      @refund_order.parent = order
      @refund_order.for_organization order.organization
      @refund_order.items = items.collect(&:to_refund)
      @refund_order.service_fee = -1 * service_fee
      @refund_order.save!
      @refund_order
    end
end