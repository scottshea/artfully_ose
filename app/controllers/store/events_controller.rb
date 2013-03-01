class Store::EventsController < Store::StoreController
  def show
    @event = Event.includes(:venue, :shows => [:chart => :sections]).find(params[:id])
  end
end