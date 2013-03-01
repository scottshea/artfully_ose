class RegularDonationKit < Kit
  acts_as_kit :with_approval => true do
    activate :if => :has_tax_info?
    activate :if => :exclusive?
    approve :unless => :no_bank_account?

    when_active do |organization|
      organization.can :receive, Donation
    end
  end

  def has_tax_info?
    errors.add(:requirements, "Your organization's tax information is missing or incomplete. Please complete it in order to active this kit.") unless organization.has_tax_info?
    organization.has_tax_info?
  end
  
  def friendly_name
    "Charity Donations"
  end
  
  def pitch
    "Receive donations for a 501(c)(3)"
  end

  def exclusive?
    exclusive = !organization.kits.where(:type => alternatives.collect(&:to_s)).any?
    errors.add(:requirements, "You have already activated a mutually exclusive kit.") unless exclusive
    exclusive
  end

  def no_bank_account?
    errors.add(:requirements, "Your organization needs bank account information first.") if organization.bank_account.nil?
    organization.bank_account.nil?
  end

  # def alternatives
  #   @alternatives ||= [ SponsoredDonationKit ]
  # end

  def on_pending
    AdminMailer.donation_kit_notification(self).deliver
    ProducerMailer.donation_kit_notification(self, organization.owner).deliver
  end
end