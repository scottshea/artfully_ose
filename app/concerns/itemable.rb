#
# Include this method on objects that can be used to create items using Item.for
# Ticket class doesn't meed it because it defines its own sold_price method
#
module Itemable
  extend ActiveSupport::Concern
  
  def sold_price
    price 
  end
end