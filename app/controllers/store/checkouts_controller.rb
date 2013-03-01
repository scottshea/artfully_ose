class Store::CheckoutsController < Store::StoreController
  layout "cart"

  def create
    unless current_cart.unfinished?
      render :json => "This order is already finished!", :status => :unprocessable_entity and return
    end

    @payment = CreditCardPayment.new(params[:payment])
    @payment.user_agreement = params[:payment][:user_agreement]
    current_cart.special_instructions = params[:special_instructions]
    
    @checkout = Checkout.new(current_cart, @payment)

    if @checkout.valid? && @checkout.finish
      render :json => @checkout.to_json
    else      
      render :json => @checkout.message, :status => :unprocessable_entity
    end
  rescue Exception => e
    Exceptional.context(:params => filter(params))
    Exceptional.handle(e, "Checkout failed!")
    message = "We're sorry but we could not process the sale.  Please make sure all fields are filled out accurately"
    render :json => message, :status => :unprocessable_entity
  end

  def filter(params)
    filters = Rails.application.config.filter_parameters
    f = ActionDispatch::Http::ParameterFilter.new filters
    f.filter params
  end
end