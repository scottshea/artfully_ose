class DailyTicketReport
  attr_accessor :rows, :daily_total, :date, :organization
  extend ::ArtfullyOseHelper

  def initialize(organization, date=nil)
    @organization = organization
    @date = date || 1.day.ago.to_date
    @orders = organization.orders.csv_not_imported.after(@date).before(@date + 1.day) || []

    @rows = []
    @orders.each do |order|
      @rows << Row.new(order) unless order.tickets.empty?
    end
  end

  def total
    DailyTicketReport.number_to_currency(@orders.sum{|o| o.tickets.sum(&:price)}.to_f/100)
  end

  def daily_total
    DailyTicketReport.number_to_currency(@orders.sum(&:total).to_f/100)
  end

  def header
    ["Order ID", "Total", "Customer", "Details", "Special Instructions"]
  end

  def to_table
    [header] + @rows.collect {|row| row.to_a.flatten(1)} << footer
  end

  def footer
    ["Total:", total, "", "", ""]
  end

  class Row
    attr_accessor :id, :ticket_details, :total, :person, :person_id, :special_instructions
    def initialize(order)
      @id = order.id
      @ticket_details = order.ticket_details
      @total = DailyTicketReport.number_to_currency(order.tickets.sum(&:price).to_f/100)
      @person = order.person
      @person_id = order.person.id
      @special_instructions = order.special_instructions
    end

    def to_a
      [id, total, person, ticket_details, special_instructions]
    end
  end
end
