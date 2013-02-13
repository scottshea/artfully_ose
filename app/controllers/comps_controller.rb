class CompsController < ArtfullyOseController
  def new
    @show = Show.find(params[:show_id])
    @selected_tickets = params[:selected_tickets]

    @comp = Comp.new(@show, @selected_tickets, nil, current_user)
    render :new
  end

  def create
    @show = Show.find(params[:show_id])
    @selected_tickets = params[:selected_tickets]
    @comp = Comp.new(@show, @selected_tickets, params[:person_id], current_user)
    unless @comp.valid?
       flash[:alert] = @comp.errors.full_messages.to_sentence
       render :new and return
    end

    @comp.reason = params[:reason_for_comp]

    with_confirmation_comp do
      @comp.submit
      if @comp.uncomped_count > 0
        flash[:alert] = "Comped #{to_plural(@comp.comped_count, 'ticket')}. #{to_plural(@comp.uncomped_count, 'ticket')} could not be comped."
      else
        flash[:notice] = "Comped #{to_plural(@comp.comped_count, 'ticket')}."
      end

      redirect_to event_show_url(@show.event, @show)
    end
  end

  def with_confirmation_comp
    if params[:confirmed].blank?
      flash[:info] = "Please confirm your changes before we save them."
      render 'comp_confirm' and return
    else
      yield
    end
  end

  private

  def recipients
    Person.search_index(params[:terms].dup, current_user.current_organization) unless params[:terms].blank?
  end
end