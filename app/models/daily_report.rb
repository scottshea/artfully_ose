class DailyReport
  attr_accessor :rows
  extend ::ArtfullyOseHelper

  def initialize(organization, date=nil)
    @organization = organization
    @date = date || 1.day.ago.to_date
    @orders = organization.orders.after(@date).before(@date + 1.day) || []

    @rows = []
    @orders.each do |order|
      @rows << Row.new(order)
    end
  end

  class Row
    attr_accessor :id, :ticket_count, :ticket_details, :total, :person
    def initialize(order)
      @id = order.id
      @ticket_count = order.tickets.count
      @ticket_details = order.ticket_details
      @total = number_to_currency(order.total.to_f/100)
      @person = order.person
    end

    comma do
      id
      ticket_count
      ticket_details
      total
      person
    end
  end
end
