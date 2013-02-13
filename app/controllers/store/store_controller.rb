class Store::StoreController < ActionController::Base
  layout "storefront"

  helper_method :current_cart
  def current_cart(reseller_id = nil)
    return @current_cart if @current_cart

    @current_cart ||= Cart.find_by_id(session[:order_id])

    if @current_cart.nil? || @current_cart.completed? || !@current_cart.reseller_is?(reseller_id)
      create_current_cart(reseller_id)
    end

    @current_cart
  end

  def current_cart=(cart)
    @current_cart = cart
  end

  private
    def create_current_cart(reseller_id)
      if reseller_id.blank?
        @current_cart = Cart.create
      else
        @current_cart = Reseller::Cart.create( {:reseller => Organization.find(reseller_id)} )
      end
      session[:order_id] = @current_cart ? @current_cart.id : nil
    end
end
