class Store::OrdersController < Store::StoreController

  def sync
    current_cart.clear!
    
    order_params = {}

    if params[:sections]
      ticket_ids = []
      over_section_limit = []
      params[:sections].each_value do |section|
        ids = Ticket.available(
          {
            :section_id => section[:section_id],
            :show_id => section[:show_id]
          },
          section[:limit]
        ).collect(&:id)
        
        if ids.length < section[:limit].to_i
          over_section_limit << {:section_id => section[:section_id], :show_id => section[:show_id], :limit => ids.length}
        end
        ticket_ids += ids
      end
      order_params = order_params.merge(:tickets => ticket_ids) if ticket_ids.any?
    end
    order_params = order_params.merge(:donation => params[:donation]) if params[:donation]

    handle_order(order_params)
    if params[:discount].present?
      begin
        handle_discount(params)
      rescue RuntimeError => e
        discount_error = e.message
        params[:discount] = nil
        @discount_amount = 0
      rescue NoMethodError => e
        discount_error = "We're sorry, we could not find your discount."
        params[:discount] = nil
        @discount_amount = 0
      end
    end

    response = current_cart.as_json
    response = response.merge(:total => current_cart.total)
    response = response.merge(:service_charge => current_cart.fee_in_cents)
    response = response.merge(:over_section_limit => over_section_limit)
    response = response.merge(:discount_error => discount_error)
    if params[:discount].present? && discount_error.blank?
      response = response.merge(:discount_name => params[:discount])
      response = response.merge(:discount_amount => current_cart.discount_amount)
    end
    render :json => response.to_json
  end

  private

    def handle_order(params)
      handle_tickets(params[:tickets]) if params.has_key? :tickets
      handle_donation(params[:donation]) if params.has_key? :donation

      unless current_cart.save
        flash[:error] = current_cart.errors
      end
    end

    def handle_discount(params)
      discount = Discount.find_by_code_and_event_id(params[:discount].upcase, event.id)
      discount.apply_discount_to_cart(current_cart)
      current_cart = discount.cart
    end

    def handle_tickets(ids)
      Ticket.find(ids).each do |ticket|
        if current_cart.can_hold? ticket
          current_cart << ticket
        else
          flash[:error] = "Your cart cannot hold any more tickets."
        end
      end
    end

    def handle_donation(data)
      if data[:amount].to_i == 0
        flash[:error] = "Please enter a donation amount."
        return
      end
      
      donation = Donation.new
      donation.amount = data[:amount]
      donation.organization = Organization.find(data.delete(:organization_id))
      current_cart.donations << donation
    end

    def event
      current_cart.tickets.first.event
    end
end
