class BuyOneGetOneFreeDiscountType < DiscountType
  discount_type :buy_one_get_one_free

  def apply_discount_to_cart
    eligible_tickets.each do |ticket|
      ticket.update_column(:discount_id, @discount.id) unless ticket == eligible_tickets.last && eligible_tickets.count.odd?
    end
    eligible_tickets.values_at(* eligible_tickets.each_index.select {|i| i.odd?}).each do |ticket|
      ticket.update_column(:cart_price, 0)
    end
  end

  def validate
    # Nothing to do here.
  end

  def to_s
    "Buy one, get one free"
  end
end
