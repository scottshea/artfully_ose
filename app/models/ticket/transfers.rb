module Ticket::Transfers
  extend ActiveSupport::Concern

  def sell_to(buyer, time=Time.now)
    begin
      self.buyer = buyer
      self.sold_at = time
      self.sell!
    rescue Transitions::InvalidTransition
      return false
    end
  end
  
  #
  # Deals solely with changing the buyer.  Pricing should be handled in exchange_prices_from
  #
  def exchange_to(buyer, time=Time.now)
    begin
      self.buyer = buyer
      self.sold_at = time
      self.exchange!
    rescue Transitions::InvalidTransition => e
      puts e
      return false
    end
  end

  def comp_to(buyer, time=Time.now)
    begin
      self.buyer = buyer
      self.sold_price = 0
      self.sold_at = time
      self.comp!
    rescue Transitions::InvalidTransition => e
      puts e
      return false
    end
  end

  def return!(and_return_to_inventory = true)
    and_return_to_inventory ? return_to_inventory! : return_off_sale!
    remove_from_cart
    self.buyer = nil
    self.sold_at = nil
    self.buyer_id = nil
    self.reset_price!
    save
  end

end