class ReportsMailer < ActionMailer::Base
  default :from => ARTFULLY_CONFIG[:contact_email]
  layout "mail"
  add_template_helper(ApplicationHelper)
  add_template_helper(ArtfullyOseHelper)

  def daily(org, date = nil)
    @date = date || 1.day.ago.to_date
    @orders = org.orders.after(@date).before(@date + 1.day) || []

    mail to: org.email, subject: "Daily Artful.ly Report for #{@date.to_s(:long)}"
  end
end
