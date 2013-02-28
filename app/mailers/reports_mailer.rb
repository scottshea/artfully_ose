class ReportsMailer < ActionMailer::Base
  default :from => ARTFULLY_CONFIG[:contact_email]
  layout "mail"
  add_template_helper(ApplicationHelper)
  add_template_helper(ArtfullyOseHelper)

  def daily(tix, donations)
    @tix = tix
    @donations = donations
    mail to: @tix.organization.email, subject: "Daily Artful.ly Report for #{@tix.date.to_s(:long)}"
  end
end
