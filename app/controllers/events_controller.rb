class EventsController < ArtfullyOseController
  respond_to :html, :json

  before_filter :find_event, :only => [ :show, :edit, :update, :destroy, :widget, :image, :storefront_link, :prices, :messages, :resell, :wp_plugin ]
  before_filter :upcoming_shows, :only => :show

  def create
    @event = Event.new(params[:event])
    @templates = current_organization.charts.template
    @event.organization_id = current_organization.id
    @event.is_free = !(current_organization.can? :access, :paid_ticketing)
    @event.venue.organization_id = current_organization.id
    @event.venue.time_zone = current_organization.time_zone
    @event.contact_email = current_organization.try(:email) || current_user.email

    if @event.save
      redirect_to edit_event_url(@event)
    else
      render :new
    end
  end

  def index
    authorize! :view, Event
    @events = current_organization.events.includes(:shows, :venue).order('updated_at DESC')
  end

  def show
    authorize! :view, @event
    @shows = @event.shows.paginate(:page => params[:page], :per_page => 25)

    respond_to do |format|
      format.json do
        render :json => @event.as_full_calendar_json
      end

      format.html do
        render :show
      end
    end

  end

  def new
    @event = current_organization.events.build(:producer => current_organization.name)
    @event.venue = Venue.new
    authorize! :new, @event
    @templates = current_organization.charts.template
  end

  def edit
    authorize! :edit, @event
  end
  
  def image
    authorize! :edit, @event
  end

  def assign
    @event = Event.find(params[:event_id])
    @chart = Chart.find(params[:chart][:id])
    @event.assign_chart(@chart)

    flash[:error] = @event.errors.full_messages.to_sentence unless @event.errors.empty?

    redirect_to event_url(@event)
  end

  def update
    authorize! :edit, @event

    if @event.update_attributes(params[:event])
      if user_requesting_next_step?
        if user_just_uploaded_an_image?
          redirect_to messages_event_path(@event)
        elsif user_set_special_instructions?
          redirect_to event_shows_path(@event)
        else
          redirect_to edit_event_venue_path(@event)
        end
      else
        flash[:notice] = "Your event has been updated."
        redirect_to event_url(@event)
      end
    else
      render :edit
    end
  end

  def destroy
    authorize! :destroy, @event
    @event.destroy
    flash[:notice] = "Your event has been deleted"
    redirect_to events_url
  end

  def widget
  end

  def storefront_link
  end

  def wp_plugin
  end
  
  def prices
  end

  def temp_discounts_index
    find_event
  end

  def temp_discount_form
    find_event

    @discount = TempDiscount.new
    @discount.promotion_type = 'two-for-one'

    @event.charts.collect(&:sections).flatten.each do |section|
      @discount.discount_sections.new(
        :section => section,
        :price => section.price
      )
    end
  end
  
  def messages
  end

  def resell
    @organization = current_organization
    @reseller_profiles = ResellerProfile.includes(:organization).order("organizations.name").all
  end

  private
    def find_event
      @event = Event.find(params[:id])
    end

    def user_set_special_instructions?
      !params[:event][:special_instructions_caption].nil?
    end

    def find_charts
      ids = params[:charts] || []
      ids.collect { |id| Chart.find(id) }
    end

    def upcoming_shows
      @upcoming = @event.upcoming_shows
    end
end
