class OrderMailer < ActionMailer::Base
  layout "mail"

  def confirmation_for(order)
    @order = order
    @person = order.person
    options = Hash.new.tap do |o|
      o[:to] = @person.email
      o[:from] = from(@order)
      o[:subject] = "Your Order"
      if order.contact_email.present?
        o[:reply_to] = order.contact_email
      end
    end
    
    mail(options)
  end

private

  def from(order)
    if ARTFULLY_CONFIG[:contact_email].present?
      ARTFULLY_CONFIG[:contact_email]
    elsif order.contact_email.present?
      order.contact_email
    else
      order.organization.email
    end
  end
end
