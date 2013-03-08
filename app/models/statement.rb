###
#
# Statement uses items from a show to calculate things like gross, net, and
# cut the data up into various sections.  The reason we don't use tickets is:
# 
# * Item is the table of record for revenue
# * a Ticket can have many items (refunds, exchanges, etc...) It's awkward (and db intensive)
#   to get the sold_item for a ticket
#
# The downside is that this approach requires a bit of hoop jumping in Row (see if, elsif, else block)
# which is indeed ugly.
#
###
class Statement  
  include Ext::Due

  attr_accessor :datetime, 
                :tickets_sold, 
                :tickets_comped, 
                :potential_revenue, 
                :gross_revenue, 
                :processing, 
                :net_revenue,
                :cc_net,
                :settled,
                :payment_method_rows,
                :order_location_rows,
                :ticket_type_rows,
                :discount_rows
  
  def self.for_show(show, imported=false)
    if show.nil?
      return new
    end
    
    new.tap do |statement|

      # Some of this overlaps with Ticket::Glance.  Consider refactoring to combine the two.
      statement.datetime          = show.datetime_local_to_event
      statement.tickets_sold      = show.tickets.select{|t| t.sold?}.size
      statement.tickets_comped    = show.tickets.select{|t| t.comped?}.size
      statement.potential_revenue = show.tickets.inject(0) { |total_price, ticket| total_price += ticket.price }
      statement.gross_revenue     = show.items.inject(0) { |gross, item| gross += item.price }
      statement.net_revenue       = show.items.inject(0) { |net, item| net += item.net }
      statement.processing        = statement.gross_revenue - statement.net_revenue
      
      statement.calculate_due(show, imported)

      #
      # PAYMENT METHOD
      #
      payment_method_hash         = show.items.group_by { |item| item.order.payment_method }
      statement.payment_method_rows         = {}
      
      # Initialize with the three common payment types
      statement.payment_method_rows[::CreditCardPayment.payment_method.downcase] = PaymentTypeRow.new(::CreditCardPayment.payment_method)
      statement.payment_method_rows[::CashPayment.payment_method.downcase] = PaymentTypeRow.new(::CashPayment.payment_method)
      statement.payment_method_rows[::CompPayment.payment_method.downcase] = PaymentTypeRow.new(::CompPayment.payment_method)
      
      payment_method_hash.each do |payment_method, items|
        payment_method = (payment_method.try(:downcase) || "")
        row = statement.payment_method_rows[payment_method] || PaymentTypeRow.new(payment_method)
        items.each {|item| row << item}
        statement.payment_method_rows[payment_method] = row
      end
      
      #
      # ORDER LOCATION
      #  
      order_location_hash         = show.items.group_by do |item| 
        item.order.original_order.location 
      end
      
      statement.order_location_rows = {}
      statement.order_location_rows[::WebOrder.location]        = OrderLocationRow.new(::WebOrder.location)
      statement.order_location_rows[BoxOffice::Order.location]  = OrderLocationRow.new(BoxOffice::Order.location)
      
      order_location_hash.each do |order_location, items|
        row = statement.order_location_rows[order_location] || OrderLocationRow.new(order_location)
        items.each {|item| row << item}
        statement.order_location_rows[order_location] = row
      end

      statement.build_discount_rows(show.items)
      statement.build_ticket_type_rows(show, show.items)
    end
  end

  #
  # TODO: These are super-related to the procs in class Slices.  Get these two on the same page and DRY it up
  #
  def build_ticket_type_rows(show, items)
    self.ticket_type_rows         = {}

    show.chart.sections.each do |section|
      self.ticket_type_rows[section.name] = TicketTypeRow.new(section.name)
    end

    items.each do |item|
      row = self.ticket_type_rows[item.product.section.name] || TicketTypeRow.new(item.product.section.name)
      row << item
      self.ticket_type_rows[item.product.section.name] = row
    end
  end

  def build_discount_rows(items)
    self.discount_rows         = {}
    items.each do |item|
      unless item.discount.nil?
        row = self.discount_rows[item.discount.code] || DiscountRow.new(item.discount.code, item.discount.promotion_type)
        row << item
        row.discount += (item.original_price - item.price)
        self.discount_rows[item.discount.code] = row
      end
    end
  end
  
  module Row
    attr_accessor :tickets, 
                  :gross,
                  :processing,
                  :net
    
    def<<(item)
      if item.refund?
        self.tickets = self.tickets - 1
      elsif item.exchanged? || item.return?
        #Noop
      else
        self.tickets = self.tickets + 1   
      end
      
      self.gross        = self.gross + item.price
      self.processing   = self.processing + (item.realized_price - item.net)
      self.net          = self.net + item.net
    end
  end
  
  class TicketTypeRow
    include Row
    attr_accessor   :ticket_type
    
    def initialize(ticket_type)
      self.ticket_type = ticket_type
      self.tickets = 0
      self.gross = 0
      self.processing = 0
      self.net = 0
    end
  end
  
  class DiscountRow
    include Row
    attr_accessor   :discount_code, :type, :discount
    
    def initialize(discount_code, type)
      self.discount_code = discount_code
      self.type = type
      self.tickets = 0
      self.gross = 0
      self.processing = 0
      self.net = 0
      self.discount = 0
    end
  end
  
  class OrderLocationRow
    include Row
    attr_accessor   :order_location
    
    def initialize(order_location)
      self.order_location = order_location
      self.tickets = 0
      self.gross = 0
      self.processing = 0
      self.net = 0
    end
  end
  
  class PaymentTypeRow
    include Row
    attr_accessor   :payment_method
    
    def initialize(payment_method)
      self.payment_method = payment_method
      self.tickets = 0
      self.gross = 0
      self.processing = 0
      self.net = 0
    end
  end
end