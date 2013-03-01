class OrdersController < ArtfullyOseController
  def index
    authorize! :manage, Order
    if params[:search]
      @results = search(params[:search]).sort{|a,b| b.created_at <=> a.created_at }.paginate(:page => params[:page], :per_page => 25)
      if @results.length == 1
        redirect_to order_path(@results.first.id)
      end
    else
      @results = current_organization.orders.includes(:person, :items).all.sort{|a,b| b.created_at <=> a.created_at }.paginate(:page => params[:page], :per_page => 25)
    end
  end

  def show
    @order = Order.includes(:items => :discount).find(params[:id])
    authorize! :view, @order
    @person = Person.find(@order.person_id)
    @total = @order.total
  end

  def resend
    authorize! :view, Order
    @order = Order.find(params[:id])
    OrderMailer.delay.confirmation_for(@order)
    
    flash[:notice] = "A copy of the order receipt has been sent to #{@order.person.email}"
    redirect_to order_url(@order)
  end

  def sales
    authorize! :view, Order

    @organization = current_user.current_organization
    @event = Event.find_by_id(params[:event_id]) if params[:event_id].present?
    @events = @organization.events_with_sales
    @show = @event.shows.find_by_id(params[:show_id]) if @event && params[:show_id].present?
    @shows = @event.shows_with_sales(@organization) if @event

    search_terms = {
      :start        => params[:start],
      :stop         => params[:stop],
      :organization => current_user.current_organization,
      :event        => @event,
      :show         => @show
    }

    @search = SaleSearch.new(search_terms) do |results|
      results.paginate(:page => params[:page], :per_page => 25)
    end
  end

  private

  def search(query)
    Order.search_index(query, current_user.current_organization)
  end

end
