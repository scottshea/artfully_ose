module Ext
  module Integrations
    module User
    end
    
    module Organization
      def self.included(base)
        base.class_eval do
          after_create do
            [TicketingKit,RegularDonationKit].each do |klass|
              kit = klass.new
              kit.state = 'activated'
              kit.organization = self
              kit.save
            end
          end
        end
      end
      
      def connected?
        false
      end 
      
      def fsp
        nil
      end

      def has_active_fiscally_sponsored_project?
        false
      end

      def has_fiscally_sponsored_project?
        false
      end

      def refresh_active_fs_project
      end

      def items_sold_as_reseller_during(date_range)
        []
      end

      def name_for_donations
        self.name
      end
      
      def update_kits
      end

      def sponsored_kit
        nil
      end
      
      def shows_with_sales
        standard =
          ::Order.
            includes(:items => { :show => :event }).
            where("orders.organization_id = ?", self.id).
            map { |o| o.items.map(&:show) }

        standard.flatten.compact.uniq.sort
      end
    end
    
    module Order
      def self.included(base)
        base.extend ClassMethods
      end
      
      def fa_id
        nil
      end
      
      module ClassMethods
        def sale_search(search)        
          standard = ::Order.includes(:items => { :show => :event })

          if search.start   
            standard = standard.after(search.start)
          end

          if search.stop   
            standard = standard.before(search.stop)
          end

          if search.organization
            standard = standard.where('orders.organization_id = ?', search.organization.id)
          end

          if search.show
            standard = standard.where("shows.id = ?", search.show.id)
          elsif search.event
            standard = standard.where("events.id = ?", search.event.id)
          end

          standard.all
        end
      end     
    end
    
    module Event
      def shows_with_sales(seller)
        standard =
          ::Order.
            includes(:items => { :show => :event }).
            where("orders.organization_id = ? AND events.id = ?", seller.id, self.id).
            map { |o| o.items.map(&:show) }

        standard.flatten.compact.uniq.sort
      end
    end
    
    module Item
      def settlement_issued?
        false
      end
    end
  end
end