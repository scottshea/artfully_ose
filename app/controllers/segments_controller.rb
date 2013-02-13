class SegmentsController < ArtfullyOseController
  def index
    authorize! :view, Segment
    @segments = current_organization.segments.paginate(:page => params[:page], :per_page => 10)
  end

  def show
    @segment = Segment.find(params[:id])
    authorize! :view, @segment
    respond_to do |format|
     format.html
     format.csv { render :csv => @segment.people, :filename => "#{@segment.name}-#{DateTime.now.strftime("%m-%d-%y")}" }
   end
  end

  def create
    authorize! :create, Segment
    @segment = current_organization.segments.build(params[:segment])
    if @segment.save
      redirect_to @segment
    else
      flash[:error] = "List segment could not be created. Please remember to type a name!"
      redirect_to session[:return_to]
    end
  end

  def destroy
    authorize! :destroy, Segment
    current_organization.segments.find(params[:id]).destroy
    redirect_to segments_path
  end
end