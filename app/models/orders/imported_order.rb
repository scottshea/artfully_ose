class ImportedOrder < ::Order
  include Unrefundable
  
  def location
    "Artful.ly"
  end
end