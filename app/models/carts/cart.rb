class Cart < ActiveRecord::Base
  include ActiveRecord::Transitions
  
  has_many :donations, :dependent => :destroy
  has_many :tickets, :after_add => :set_timeout
  after_destroy :clear!
  attr_accessor :special_instructions

  belongs_to :discount

  state_machine do
    state :started
    state :approved
    state :rejected

    event(:approve, :success => :record_sold_price) { transitions :from => [ :started, :rejected ], :to => :approved }
    event(:reject)  { transitions :from => [ :started, :rejected ], :to => :rejected }
  end

  delegate :empty?, :to => :items
  def items
    self.tickets + self.donations
  end
    
  def checkout_class
    Checkout
  end

  def clear!
    reset_prices_on_tickets
    clear_tickets
    clear_donations
  end
  
  def as_json(options = {})
    super({ :methods => [ 'tickets', 'donations' ]}.merge(options))
  end
  
  def clear_tickets
    release_tickets
    self.tickets = []
  end

  def release_tickets
    tickets.each { |ticket| ticket.remove_from_cart }
  end

  def set_timeout(ticket)
    save if new_record?
    
    if Delayed::Worker.delay_jobs
      self.delay(:run_at => Time.now + 10.minutes).expire_ticket(ticket)
    end
  end

  def expire_ticket(ticket)
    ticket.reset_price!
    tickets.delete(ticket)
  end

  def items_subject_to_fee
    self.tickets.reject{|t| t.price == 0}
  end

  def fee_in_cents
    items_subject_to_fee.size * (ARTFULLY_CONFIG[:ticket_fee] || 0)
  end

  def clear_donations
    temp = []

    #This won't work if there is more than 1 FAFS donation on the order
    donations.each do |donation|
      temp = donations.delete(donations)
    end
    temp
  end

  def <<(tkts)
    self.tickets << tkts
  end

  def subtotal
    items.sum(&:price)
  end

  def total_before_discount
    items.sum(&:price) + fee_in_cents
  end

  def total
    items.sum(&:cart_price) + fee_in_cents
  end

  def discount_amount
    total_before_discount - total
  end

  def unfinished?
    started? or rejected?
  end

  def completed?
    approved?
  end

  def pay_with(payment, options = {})
    @payment = payment

    #TODO: Move the requires_authorization? check into the payments classes.  Cart shouldn't care
    if payment.requires_authorization?
      options[:service_fee] = fee_in_cents
      pay_with_authorization(payment, options)
    else
      approve!
    end
  end

  def finish
    metric_sale_total
  end

  def generate_donations
    organizations_from_tickets.collect do |organization|
      if organization.can?(:receive, Donation)
        donation = Donation.new
        donation.organization = organization
        donation
      end
    end.compact
  end

  def organizations
    (organizations_from_donations + organizations_from_tickets).uniq
  end

  def organizations_from_donations
    Organization.find(donations.collect(&:organization_id))
  end

  def organizations_from_tickets
    Organization.find(tickets.collect(&:organization_id))
  end

  def can_hold?(ticket)
    true
  end

  def reseller_is?(reseller)
    reseller == nil
  end

  def reset_prices_on_tickets
    transaction do
      tickets.each {|ticket| ticket.reset_price! }
    end
  end

  private

    def record_sold_price
      self.tickets.each do |ticket|
        ticket.sold_price = ticket.cart_price || ticket.price
        ticket.save
      end
    end

    def pay_with_authorization(payment, options)
      payment.purchase(options) ? approve! : reject!
    end

    def metric_sale_total
      bracket =
        case self.total
        when 0                  then "$0.00"
        when (1 ... 1000)       then "$0.01 - $9.99"
        when (1000 ... 2000)    then "$10 - $19.99"
        when (2000 ... 5000)    then "$20 - $49.99"
        when (5000 ... 10000)   then "$50 - $99.99"
        when (10000 ... 25000)  then "$100 - $249.99"
        when (25000 ... 50000)  then "$250 - $499.99"
        else                         "$500 or more"
        end

      RestfulMetrics::Client.add_compound_metric(ENV["RESTFUL_METRICS_APP"], "sale_complete", [ bracket ])
    end

end
