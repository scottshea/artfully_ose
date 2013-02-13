class MergesController < ArtfullyOseController
  def new
    @loser = Person.find(params[:loser])
    without_winner do
      if is_search(params)
        @people = Person.search_index(params[:search].dup, current_user.current_organization)
      else
        @people = Person.recent(current_user.current_organization)
      end
      @people = @people.paginate(:page => params[:page], :per_page => 20)  
      @people = @people.reject { |person| person.id == @loser.id }  
      render :find_person
    end
  end
  
  def create
    @winner = Person.find(params[:winner])
    @loser = Person.find(params[:loser])
    @result = Person.merge(@winner, @loser)
    flash[:notice] = "#{@loser} has been merged into this record"
    redirect_to person_path(:id => @winner.id)
  end

  private    
    def is_search(params)
      params[:commit].present?
    end    
    
    def without_winner
      if params[:winner]
        @winner = Person.find(params[:winner])
        render :new and return
      else
        yield
      end
    end
end