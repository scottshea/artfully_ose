class DailyDonationReport
  attr_accessor :rows, :donation_total, :date, :organization
  extend ::ArtfullyOseHelper

  def initialize(organization, date=nil)
    @organization = organization
    @date = date || 1.day.ago.to_date
    @orders = organization.orders.after(@date).before(@date + 1.day) || []

    @rows = []
    @orders.each do |order|
      @rows << Row.new(order) unless order.donations.empty?
    end
  end

  def total
    DailyDonationReport.number_to_currency(@orders.sum{|o| o.donations.sum(&:total_price)}.to_f/100)
  end

  def header
    ["Order ID", "Total", "Customer"]
  end

  def to_table
    [header] + @rows.collect {|row| row.to_a.flatten(1)} << footer
  end

  def footer
    ["Total:", total, ""]
  end

  class Row
    attr_accessor :id, :total, :person, :person_id
    def initialize(order)
      @id = order.id
      @total = DailyDonationReport.number_to_currency(order.donations.sum(&:total_price).to_f/100)
      @person = order.person
      @person_id = order.person.id
    end

    def to_a
      [id, total, person]
    end
  end
end
