class DailyEmailReportJob
  def self.perform
    Organization.all.each do |org|
      daily_report = DailyReport.new(org)
      ReportsMailer.daily(daily_report).deliver
    end
  end
end
