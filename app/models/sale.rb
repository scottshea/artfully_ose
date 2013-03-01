class Sale
  include ActiveModel::Validations

  attr_accessor :sections, :quantities, :tickets, :cart, :message, :error, :sale_made
  attr_reader :buyer

  validate :has_tickets?

  def initialize(show, sections, quantities = {})
    @show       = show
    @sections   = sections
    
    #When coming from a browser, all keys and values in @quantities are STRINGS
    @quantities = quantities
    @cart       = BoxOffice::Cart.new
    @tickets     = []
    
    #This is irritating, it means you can't add tickets to a sale later
    load_tickets      
    cart.tickets << tickets
  end

  def sell(payment)
    if valid?
      case payment
      when CompPayment
        @sale_made = comp_tickets(payment)
      else
        @sale_made = sell_tickets(payment)
      end
    else
      @sale_made = false
    end
    @sale_made
  end

  def non_zero_quantities?
    @quantities.each do |k,v|
      return true if (v.to_i > 0)
    end
    false
  end

  def load_tickets
    sections.each do |section|
      tickets_available_in_section = Ticket.available({:section_id => section.id, :show_id => @show.id}, @quantities[section.id.to_s])
      if tickets_available_in_section.length != @quantities[section.id.to_s].to_i
        errors.add(:base, "There aren't enough tickets available in that section")
      else
        @tickets = @tickets + tickets_available_in_section
      end
    end
  end
  
  def has_tickets?
    unless non_zero_quantities?
      errors.add(:base, "Please select a number of tickets to purchase") and return false
    end
    errors.add(:base, "no tickets were added") unless @tickets.size > 0
    @tickets.size > 0
  end

  private

    def comp_tickets(payment)
      @comp = Comp.new(tickets.first.show, tickets, payment.customer, payment.benefactor)
      @comp.submit
      @buyer = @comp.recipient
      true
    end
    
    def sell_tickets(payment)
      checkout = BoxOffice::Checkout.new(cart, payment)
      begin
        success = checkout.finish
        @buyer = checkout.person
        if !success
          if checkout.payment.errors.blank?
            errors.add(:base, "payment was not accepted")
          else
            errors.add(:base, checkout.payment.errors.full_messages.to_sentence.downcase) 
          end
          return success
        end
      rescue Errno::ECONNREFUSED => e
        errors.add(:base, "Sorry but we couldn't connect to the payment processor.  Try again or use another payment type")
      rescue Exception => e
        ::Rails.logger.error e
        ::Rails.logger.error e.backtrace
        errors.add(:base, "We had a problem processing the sale")
      end
      success
    end
end