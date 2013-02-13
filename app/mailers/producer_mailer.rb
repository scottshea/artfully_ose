class ProducerMailer < ActionMailer::Base
  default :from => ARTFULLY_CONFIG[:contact_email]
  layout "mail"

  def donation_kit_notification(kit, producer)
    @kit = kit
    @organization = kit.organization
    @producer = producer

    mail :to => producer.email, :subject => "Artful.ly: Complete Donation Kit Activation for #{@organization.name}"
  end

  def ticket_offer_accepted(ticket_offer)
    @ticket_offer = ticket_offer
    @organization = ticket_offer.organization
    @producer = @organization.owner
    @reseller_profile = ticket_offer.reseller_profile
    @reseller = @reseller_profile.organization
    @event = @ticket_offer.event
    @show = @ticket_offer.show
    @section = @ticket_offer.section

    mail :to => @producer.email, :subject => "Artful.ly: Ticket Offer Accepted"
  end

  def ticket_offer_rejected(ticket_offer)
    @ticket_offer = ticket_offer
    @organization = ticket_offer.organization
    @producer = @organization.owner
    @reseller_profile = ticket_offer.reseller_profile
    @reseller = @reseller_profile.organization
    @event = @ticket_offer.event
    @show = @ticket_offer.show
    @section = @ticket_offer.section

    mail :to => @producer.email, :subject => "Artful.ly: Ticket Offer Rejected"
  end

  def mailchimp_kit_initial_sync_notification(kit, producer, list_name)
    @kit = kit
    @list_name = list_name
    @organization = kit.organization

    mail :to => producer.email, :subject => "Artful.ly: MailChimp kit synced"
  end
end
