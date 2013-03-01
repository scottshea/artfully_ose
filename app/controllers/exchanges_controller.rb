class ExchangesController < ArtfullyOseController
  def new
    @items = Item.includes(:product => [:show => [:event => :venue]]).where(:id => params[:items])

    if @items.all?(&:exchangeable?)
      @events = current_organization.events

      unless params[:event_id].blank?
        @event = Event.find(params[:event_id])
        @shows = @event.upcoming_shows(:all)
        unless params[:show_id].blank? || @event.blank?
          @show = Show.includes(:event => :venue, :chart => :sections).find(params[:show_id])
          unless params[:section_id].blank? || @show.blank?
            @section = Section.find(params[:section_id])
            @tickets = @show.tickets.unsold.where(:section_id => @section.id)
            @free_upgrade = @tickets.first.price > @items.first.price unless @tickets.empty?
          end
        end
      end
    else
      flash[:error] = "Some of the selected items are not exchangable."
      redirect_to order_url(params[:order_id])
    end
  end

  def create
    order = Order.find(params[:order_id])
    items = params[:items].collect { |item_id| Item.find(item_id) }
    tickets = Ticket.available({section_id: params[:section_id], show_id: params[:show_id]}, items.count)
    logger.debug("Beginning exchange")
    @exchange = Exchange.new(order, items, tickets)

    if tickets.nil?
      flash[:error] = "Please select tickets to exchange."
      redirect_to :back
    elsif tickets.size != items.size
      flash[:error] = "There were not enough tickets available for this show. (#{items.size} needed, #{tickets.size} available.)"
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