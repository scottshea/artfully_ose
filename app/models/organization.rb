class Organization < ActiveRecord::Base
  include Valuation::LifetimeValue
  include Ext::Resellable::Organization
  include Ext::Integrations::Organization
  
  attr_accessible :name, :time_zone, :ein, :legal_organization_name, :email, :receive_daily_sales_report
  
  has_many :events
  has_many :charts
  has_many :shows
  has_many :tickets
  has_many :discounts

  has_many :people
  has_many :segments

  has_many :memberships
  has_many :orders
  has_many :items

  has_many :users, :through => :memberships
  has_many :kits, :before_add => :check_for_duplicates,
                  :after_add => lambda { |u,k| k.activate! unless k.activated? }

  has_many :imports

  validates_presence_of :name, :email
  validates :ein, :presence => true, :if => :updating_tax_info
  validates :legal_organization_name, :presence => true, :if => :updating_tax_info

  scope :receiving_sales_email, where(:receive_daily_sales_report => true)

  #
  # We aren't interested in FAFS donations, so override lifetime_orders
  # to only include Artfully orders  see: Valuation::LifetimeValue
  #
  def lifetime_orders
    orders.where('transaction_id is not null')
  end

  #
  # Returns Tag objects.  For an array of tag strings, call unique_tag_strings_for
  #
  # This has been supersceded by tags_on and tag_counts_on in acts_as_taggable_on
  # But those methods have not been added to a release yet.
  #
  def tags_for(tagged_association)
    
    #Yak
    begin
      self.send(tagged_association.to_sym)
    rescue NoMethodError
      raise NoMethodError, "No tagged has_many association found for #{tagged_association.to_sym}"
    end

    table_name = Kernel.const_get(tagged_association.to_s.classify).table_name
    
    ActsAsTaggableOn::Tag.joins("INNER JOIN taggings ON tags.id = taggings.tag_id")
                         .joins("INNER JOIN #{table_name} ON #{table_name}.id = taggings.taggable_id")
                         .joins("INNER JOIN organizations ON organizations.id = #{table_name}.organization_id")
                         .where("organizations.id = ?", self.id)
  end

  def unique_tag_strings_for(tagged_association)
    self.tags_for(tagged_association).all.map(&:name).uniq
  end

  def owner
    users.first
  end

  def dummy
    Person.dummy_for(self)
  end

  delegate :can?, :cannot?, :to => :ability
  def ability
    OrganizationAbility.new(self)
  end

  attr_accessor :updating_tax_info
  def update_tax_info(params)
    @updating_tax_info = true
    update_attributes({
      :ein => params[:ein],
      :legal_organization_name => params[:legal_organization_name],
      :email => params[:email]
    })
  end

  def has_tax_info?
    !(ein.blank? or legal_organization_name.blank?)
  end

  def available_kits
    Kit.pad_with_new_kits(kits)
  end

  def authorization_hash
    { :authorized   => can?(:receive, Donation),
      :type         => donation_type,
      :fsp_name     => name_for_donations  }
  end

  def donations
    Item.joins(:order).where(:product_type => "Donation", :orders => { :organization_id => id })
  end

  def ticket_sales
    Item.joins(:order).where(:product_type => "Ticket", :orders => { :organization_id => id })
  end

  def has_kit?(name)
    kits.where(:state => "activated").map(&:class).map(&:name).include?(name.to_s.camelize + "Kit")
  end

  def events_with_sales
    shows_with_sales.map(&:event).uniq
  end

  private

    def check_for_duplicates(kit)
      raise Kit::DuplicateError if kits.find{|k| k.type == kit.type}
    end

    def donation_type
      return :sponsored if kits.where(:type => "SponsoredDonationKit").any? && kits.where(:type => "SponsoredDonationKit").first.activated?
      return :regular if kits.where(:type => "RegularDonationKit").any? && kits.where(:type => "RegularDonationKit").first.activated?
    end
end
