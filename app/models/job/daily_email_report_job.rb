class DailyEmailReportJob
  def self.perform
    Organization.all.each do |org|
      tickets = DailyTicketReport.new(org)
      donations = DailyDonationReport.new(org)
      next if tickets.rows.empty?
      ReportsMailer.daily(tickets, donations).deliver
    end
  end
end
