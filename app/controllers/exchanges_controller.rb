class ExchangesController < ArtfullyOseController
  def new
    order = Order.find(params[:order_id])
    items = params[:items].collect { |item_id| Item.find(item_id) }

    if items.all?(&:exchangeable?)
      @events = current_organization.events

      unless params[:event_id].blank?
        @event = Event.find(params[:event_id])
        @shows = @event.upcoming_shows(:all)
        unless params[:show_id].blank?
          @show = Show.find(params[:show_id])
          unless params[:section_id].blank?
            @section = Section.find(params[:section_id])
            @tickets = @show.tickets.unsold.where(:section_id => @section.id)
          end
        end
      end
    else
      flash[:error] = "Some of the selected items are not exchangable."
      redirect_to order_url(order)
    end
  end

  def create
    order = Order.find(params[:order_id])
    items = params[:items].collect { |item_id| Item.find(item_id) }
    tickets = params[:tickets].collect { |ticket_id| Ticket.find(ticket_id) } unless params[:tickets].nil?
    logger.debug("Beginning exchange")
    @exchange = Exchange.new(order, items, tickets)

    if tickets.nil?
      flash[:error] = "Please select tickets to exchange."
      redirect_to :back
    elsif tickets.size > items.size
      flash[:error] = "You are exchanging #{self.class.helpers.pluralize(items.length, 'ticket')} but selected #{self.class.helpers.pluralize(tickets.size, 'ticket')}.  Please select #{self.class.helpers.pluralize(items.length, 'ticket')} to exchange."
      redirect_to :back
    elsif @exchange.valid?
      logger.debug("Submitting exchange")
      @exchange.submit
      redirect_to order_url(order), :notice => "Successfully exchanged #{self.class.helpers.pluralize(items.length, 'ticket')}"
    else
      flash[:error] = "Unable to process exchange."
      redirect_to :back
    end
  end
end