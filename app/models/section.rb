class Section < ActiveRecord::Base
  include Ticket::Foundry
  foundry :with => lambda { { :section_id => id, :price => price, :count => capacity } }

  attr_accessible :name, :capacity, :price, :chart_id, :old_mongo_id, :description
  delegate :show, :to => :chart

  belongs_to :chart
  has_many :tickets

  validates :name, :presence => true

  validates :price, :presence => true,
                    :numericality => true

  validates :capacity,  :presence => true,
                        :numericality => { :less_than_or_equal_to => 2000 }

  validates :description, :length => { :maximum => 500 }
  
  # Each channel needs its own boolean column in the sections table.
  @@channels = { :storefront => "S", :box_office => "B"}
  @@channels.each do |channel_name, icon|
    attr_accessible channel_name
    self.class.send(:define_method, channel_name) do
      where(channel_name => true)
    end
  end
  
  def channels
    @@channels
  end

  def dup!
    Section.new(self.attributes.reject { |key, value| key == 'id' })
  end
  
  def self.price_to_cents(price_in_dollars)
    (price_in_dollars.to_f * 100).to_i
  end

  def summarize
    tickets = Ticket.where(:section_id => id)
    @summary = SectionSummary.for_tickets(tickets)
  end
  
  def put_on_sale(qty = 0)
    tickets.off_sale.limit(qty).each do |t|
      t.put_on_sale
    end
  end
  
  def take_off_sale(qty = 0)
    tickets.on_sale.limit(qty).each do |t|
      t.take_off_sale
    end
  end
  
  def available
    Ticket.on_sale.where(:section_id => self.id).where(:cart_id => nil).count
  end

  def summary
    @summary || summarize
  end

  def as_json(options = {})
    options ||= {}
    super(:methods => :summary).merge(options)
  end
end
