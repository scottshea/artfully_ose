class ReportsMailer < ActionMailer::Base
  default :from => ARTFULLY_CONFIG[:contact_email]
  layout "mail"
  add_template_helper(ApplicationHelper)
  add_template_helper(ArtfullyOseHelper)

  def daily(report)
    @report = report
    mail to: @report.organization.email, subject: "Daily Artful.ly Report for #{@report.date.to_s(:long)}"
  end
end
