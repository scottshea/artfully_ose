class Comp
  include ActiveModel::Conversion 
  include ActiveModel::Validations
  extend ActiveModel::Naming

  validate :valid_recipient_and_benefactor

  attr_accessor :show, :tickets, :recipient, :benefactor, :reason, :order
  attr_accessor :comped_count, :uncomped_count

  #tickets can be an array of tickets_ids or an array of tickets
  def initialize(show, tickets_or_ids, recipient, benefactor)
    @show = show
    @tickets = []
    load_tickets(tickets_or_ids)
    @recipient = Person.find(recipient) unless recipient.blank?
    @benefactor = benefactor
  end
  
  def valid_recipient_and_benefactor
    if @recipient.nil?
      errors.add(:base, "Please select a person to comp to or create a new person record")
      return
    end
    
    if @benefactor.nil?
      errors.add(:base, "Please select a benefactor")
      return
    end
    
    unless @benefactor.current_organization.eql? @recipient.organization
      errors.add(:base, "Recipient and benefactor are from different organizations")
    end
  end

  def has_recipient?
    !recipient.blank?
  end

  def persisted?
    false
  end

  def submit
    ActiveRecord::Base.transaction do
      create_order(@tickets, recipient, @benefactor)
      self.comped_count    = tickets.size
      self.uncomped_count  = 0
    end
  end

  private
    def load_tickets(tickets_or_ids)
      tickets_or_ids.each do |t|
        t = Ticket.find(t) unless t.kind_of? Ticket
        @tickets << t
      end
    end
  
    def create_order(comped_tickets, recipient, benefactor)
      @order = CompOrder.new
      @order << comped_tickets
      @order.person = recipient
      @order.organization = benefactor.current_organization
      @order.details = "Comped by: #{benefactor.email} Reason: #{reason}"
      @order.to_comp!
    
      if 0 < comped_tickets.size
        @order.save
      end
    end
end