class RefundsController < ArtfullyOseController
  def new
    @order = Order.find(params[:order_id])
    @items = params[:items].collect { |item_id| Item.find(item_id) }
  end

  def create
    @order = Order.find(params[:order_id])
    @items = params[:items].collect { |item_id| Item.find(item_id) }

    @refund = Refund.new(@order, @items)
    @refund.submit(:and_return => return_items?)

    if @refund.successful?
      if return_items?
        flash[:notice] = "Successfully refunded and returned #{@refund.items.size} items."
      else
        flash[:notice] = "Successfully refunded #{@refund.items.size} items."
      end
    else
      if @refund.gateway_error_message.nil?
        flash[:error] = "Unable to refund items.  Please contact support and we'll try to help!"
      else
        flash[:error] = "Unable to refund items: " + @refund.gateway_error_message
      end
    end

    redirect_to order_url(@order)
  end

  private

  def return_items?
    @return_items ||= (params[:commit] == "Issue Refund and Return" and @items.all?(&:returnable?))
  end
end