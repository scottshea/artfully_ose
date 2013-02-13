class Return
  attr_accessor :order, :items

  def initialize(order, items)
    self.order = order
    self.items = items
  end

  def submit
    @success = items.map(&:return!).reduce(&:&)
  end

  def successful?
    @success || false
  end
end