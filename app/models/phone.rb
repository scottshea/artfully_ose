class Phone < ActiveRecord::Base
  attr_accessible :kind, :number
  belongs_to :person

  #This method is here solely to parse phones in the Athena migration
  #There were in the form type:number
  def self.from_athena(unparsed_phone)
    Phone.new.tap do |phone|
      phone.kind, phone.number = unparsed_phone.split(":")
    end
  end

  def self.kinds
    [ "Work", "Home", "Cell", "Fax", "Other" ]
  end
end
