class ActionsController < ArtfullyOseController

  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = exception.message
    redirect_to root_path
  end

  def new
    @action = Action.new
    @person = Person.find(params[:person_id])

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
    @person = Person.find(params[:person_id])

    @action = Action.create_of_type(params[:action_type])
    @action.set_params(params[:artfully_action], @person)
    @action.set_creator(current_user)

    if @action.save
      flash[:notice] = "Action logged successfully!"
      redirect_to person_url(@person)
    else
      flash[:alert] = "One or more fields are invalid!"
      redirect_to :back
    end

  end

  def update
    @person = Person.find params[:person_id]

    @action = Action.find params[:id]
    @action.set_params(params[:artfully_action], @person)

    if @action.valid? && @action.save!
      flash[:notice] = "Action updated successfully!"
      redirect_to person_url(@person)
    else
      flash[:alert] = "There was a problem editing your action, please contact support if the problem persists."
      redirect_to :back
    end

  end

end
