module Imports
  module Rollback  
    def rollback_orders
      Order.where(:import_id => self.id).where(:organization_id => self.organization.id).all.each {|o| o.destroy(:with_prejudice => true)}
    end
  
    def rollback_people
      Person.where(:import_id => self.id).where(:organization_id => self.organization.id).all.each {|p| p.destroy}
    end
  end
end