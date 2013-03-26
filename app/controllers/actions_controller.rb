class ActionsController < ArtfullyOseController

  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = exception.message
    redirect_to root_path
  end

  def new
    @action = Action.new
    @form_action = form_action
    @action.creator = nil
    @action.occurred_at = DateTime.now.in_time_zone(current_user.current_organization.time_zone)
    render :layout => false
  end

  def edit
    @action = Action.find(params[:id])
    @person = Person.find(params[:person_id])
    render :layout => false
  end

  def create
    return apply_to_person if params[:person_id]
    return apply_to_search if params[:search_id] || params[:segment_id]
  end

  def update
    @person = Person.find params[:person_id]

    @action = Action.find params[:id]
    @action.set_params(params[:artfully_action], @person)

    if @action.valid? && @action.save!
      flash[:notice] = "Action has been logged"
      redirect_to person_url(@person)
    else
      flash[:alert] = "There was a problem editing your action, please contact support if the problem persists."
      redirect_to :back
    end

  end

  private
    def apply_to_person
      @person = Person.find(params[:person_id])
      authorize! :edit, @person
      @action = Action.create_of_type(params[:action_type])
      @action.set_params(params[:artfully_action], @person)
      @action.set_creator(current_user)

      if @action.save
        flash[:notice] = "Action has been logged"
        redirect_to person_url(@person)
      else
        flash[:alert] = "We're sorry but we could not save your action.  One or more fields are invalid."
        redirect_to :back
      end
    end


    def form_action
      return "person_actions_path" if params[:person_id]
      return "search_actions_path" if params[:search_id]
      return "segment_actions_path" if params[:segment_id]
    end

    def apply_to_search
      @search = params[:search_id] ? Search.find(params[:search_id]) : Segment.find(params[:segment_id]).search
      authorize! :edit, @search
      @action = Action.create_of_type(params[:action_type])
      @action.set_params(params[:artfully_action], nil) 
      @action.set_creator(current_user)
      @search.attach_action(@action)  
      flash[:notice] = "We're setting actions on all those people and will be done in just a few minutes."
      redirect_to params[:search_id] ? search_url(@search) : segment_url(Segment.find(params[:segment_id]))
    end

end
