class DailyReport
  attr_accessor :rows, :daily_total
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

  def daily_total
    DailyReport.number_to_currency(@orders.sum(&:total).to_f/100)
  end

  def header
    ["Order ID", "Total", "Customer", "Details"]
  end

  def to_a
    [header] << @rows.collect {|row| row.to_a} << [footer]
  end

  def footer
    ["Daily Total:", daily_total, "", ""]
  end

  class Row
    attr_accessor :id, :ticket_details, :total, :person, :person_id
    def initialize(order)
      @id = order.id
      @ticket_details = order.ticket_details
      @total = DailyReport.number_to_currency(order.total.to_f/100)
      @person = order.person
      @person_id = order.person.id
    end

    def to_a
      [id, total, person, ticket_details]
    end
  end
end
