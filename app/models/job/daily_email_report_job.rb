class DailyEmailReportJob
  def self.perform
    org_ids = Order.csv_not_imported.after(@date).before(@date + 1.day).pluck(:organization_id).uniq
    Organization.where(:id => org_ids).receiving_sales_email.each do |org|
      tickets = DailyTicketReport.new(org)
      donations = DailyDonationReport.new(org)
      next if tickets.rows.empty? && donations.rows.empty?
      ReportsMailer.daily(tickets, donations).deliver
    end
  end
end
