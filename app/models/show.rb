class Show < ActiveRecord::Base
  include Ticket::Foundry  
  include Ticket::Reporting
  include ActiveRecord::Transitions
  include Ext::Resellable::Show
  include Ext::Integrations::Show
  include Ext::Uuid

  attr_accessible :datetime, :event_id, :chart_id, :organization_id, :old_mongo_id
  
  belongs_to :organization
  belongs_to :event
  belongs_to :chart, :autosave => true

  has_many :tickets, :dependent => :destroy

  has_many :settlements
  has_many :items
  
  before_destroy :destroyable?

  has_many :reseller_attachments, :as => :attachable

  has_and_belongs_to_many :discounts

  validates_presence_of :datetime
  validates_presence_of :chart_id
  validates_datetime :datetime, :after => lambda { Time.now }

  set_watch_for :datetime, :local_to => :organization
  set_watch_for :datetime, :local_to => :event
  set_watch_for :datetime, :local_to => :unscoped_event

  scope :before,    lambda { |time| where("shows.datetime <= ?", time) }
  scope :after,     lambda { |time| where("shows.datetime >= ?", time) }
  scope :in_range,  lambda { |start, stop| after(start).before(stop) }
  scope :played,    lambda { where("shows.datetime < ?", Time.now) }
  scope :unplayed,  lambda { where("shows.datetime > ?", Time.now) }

  foundry :using => :chart, :with => lambda {{:show_id => self.id, :organization_id => organization_id}}

  delegate :free?, :to => :event

  state_machine do
    
    #pending and built are deprecated, left in only because we have shows in production which are built
    state :pending
    state :built, :exit => :create_and_on_sale_tickets
    state :published
    state :unpublished

    event(:build)     { transitions :from => :pending, :to => :built }
    event(:publish, :success => :record_publish)   { transitions :from => [ :built, :unpublished ], :to => :published }
    event(:unpublish) { transitions :from => [ :built, :published ], :to => :unpublished }
  end

  #wraps build, publish (or unpublish), and save
  def go!(and_publish = true)
    return false if !valid?
    transaction do
      build!    
      and_publish ? publish! : unpublish!
      save
    end
  end

  def create_and_on_sale_tickets
    create_tickets
    bulk_on_sale(:all)
  end

  def unscoped_event
    ::Event.unscoped.find(event_id)
  end
  
  def imported?
    unscoped_event.imported?
  end
  
  def event_deleted?
    !unscoped_event.deleted_at.nil?
  end

  def gross_potential
    @gross_potential ||= tickets.inject(0) { |sum, ticket| sum += ticket.price.to_i }
  end

  def gross_sales
    @gross_sales ||= tickets_sold.inject(0) { |sum, ticket| sum += ticket.price.to_i }
  end

  def tickets_sold
    @tickets_sold ||= tickets.select { |ticket| ticket.sold? }
  end

  def tickets_comped
    @tickets_comped ||= tickets.select { |ticket| ticket.comped? }
  end

  def self.next_datetime(show)
    show.nil? ? future(Time.now.beginning_of_day + 20.hours) : future(show.datetime_local_to_event + 1.day)
  end

  def has_door_list?
    published? or unpublished?
  end

  def time_zone
    @time_zone ||= event.time_zone
  end

  def load(attrs)
    super(attrs)
    set_attributes(attrs)
  end

  def dup!
    copy = Show.new(self.attributes.reject { |key, value| key == 'id' || key == 'uuid' || key == 'state' })
    copy.event = self.event
    copy.datetime = copy.datetime + 1.day
    copy
  end

  def show_time
    I18n.l(datetime_local_to_event, :format => :long_with_day)
  end

  def as_json(options={})
    { "id" => id,
      "uuid" => uuid,
      "chart_id" => chart.id,
      "state" => state,
      "show_time" => show_time,
      "datetime" => datetime_local_to_event,
      "destroyable" => destroyable?
    }
  end

  def bulk_on_sale(ids)
    Ticket.put_on_sale(get_targets(ids))
  end

  def bulk_off_sale(ids)
    Ticket.take_off_sale(get_targets(ids))
  end

  def bulk_delete(ids)
    tickets.where(:id => ids).collect{ |ticket| ticket.id if ticket.destroy }#.compact
  end

  def bulk_change_price(ids, price)
    tickets.where(:id => ids).collect{ |ticket| ticket.id if ticket.change_price(price) }.compact
  end

  def settleables
    items.reject(&:modified?)
  end

  def reseller_settleables
    settleables = {}

    items.includes(:reseller_order).select(&:reseller_order).reject(&:modified?).each do |item|
      reseller = item.reseller_order.organization
      settleables[reseller] ||= []
      settleables[reseller] << item
    end

    settleables
  end

  def destroyable?
    (tickets_comped + tickets_sold).empty? && items.empty?
  end

  def live?
    (tickets_comped + tickets_sold).any?
  end

  def played?
    datetime < Time.now
  end

  def on_saleable_tickets
    tickets.select(&:on_saleable?)
  end

  def off_saleable_tickets
    tickets.select(&:off_saleable?)
  end

  def destroyable_tickets
    tickets.select(&:destroyable?)
  end

  def compable_tickets
    tickets.select(&:compable?)
  end

  def as_widget_json(options = {})
    as_json.merge(:event => event.as_json, :venue => event.venue.as_json, :chart => chart.as_json)
  end

  def <=>(obj)
    return -1 unless obj.kind_of? Show

    if self.event == obj.event
      self.datetime <=> obj.datetime
    else
      self.event <=> obj.event
    end
  end

  def reseller_sold_count
    self.ticket_offers.inject(0) { |sum, to| sum + to.sold }
  end

  private

  def self.future(date)
    return date if date > Time.now
    offset = date - date.beginning_of_day
    future(Time.now.beginning_of_day + offset + 1.day)
  end

  def bulk_comp(ids)
    tickets.select { |ticket| ids.include? ticket.id }.collect{ |ticket| ticket.id unless ticket.comp_to }.compact
  end

  def get_targets(ids)
    (ids == :all) ? tickets : tickets.where(:id => ids)
  end
end
