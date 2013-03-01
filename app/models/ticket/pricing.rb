module Ticket::Pricing
  extend ActiveSupport::Concern

  def remove_from_cart
    self.update_column(:cart_id, nil)
  end

  #
  # This is guarded with sold? Because of the DelayedJob that expires tickets.  The job 
  # Removes them from cart regardless of state.  If they've been sold, we want that information retained
  #
  def reset_price!
    return false if sold?
    
    self.cart_price = self.price
    self.discount = nil
    self.sold_price = nil
    self.save
  end 

  def exchange_prices_from(old_ticket)
    self.sold_price = old_ticket.sold_price
    self.cart_price = old_ticket.sold_price
    self.discount_id= old_ticket.discount_id
    self.cart_id = nil
    self.save
  end

  def set_cart_price
    self.cart_price ||= self.price
  end

  def cart_price
    self[:cart_price] || self.price
  end

  def change_price(new_price)
    unless self.committed? or new_price.to_i < 0
      self.price = new_price
      self.save!
    else
      return false
    end
  end
end