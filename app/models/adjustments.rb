module Adjustments
  def service_fee_per_item(itmz)
    #ternery operation solely to avoid dividing by zero
    number_of_non_free_items(itmz) == 0 ? 0 : (order.service_fee || 0) / number_of_non_free_items(itmz)
  end

  def number_of_non_free_items(itmz)
    itmz.reject{|item| item.original_price == 0}.size
  end
end