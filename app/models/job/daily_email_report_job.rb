class DailyEmailReportJob
  def self.perform
    Organization.receiving_sales_email.includes(:orders => [:person, :items]).each do |org|
      tickets = DailyTicketReport.new(org)
      donations = DailyDonationReport.new(org)
      next if tickets.rows.empty?
      ReportsMailer.daily(tickets, donations).deliver
    end
  end
end
