module Ext
  #
  # Includers will have a uuid generated for them before_create
  # Method self.multi_find can be used to find by either id or uuid
  #
  # Requires a :uuid column on the including class
  # 
  module Uuid
    
    #Required to prevent Ruby from parsing uuid's with leading digits into a primary key id
    PREFIX = "art-"

    def self.included(base)
      base.class_eval do
        before_create :set_uuid
      end
      base.extend ClassMethods
    end

    module ClassMethods
      def multi_find(key)
        arel = self.arel_table
        where(arel[:id].eq(key).or(arel[:uuid].eq(key))).first
      end
    end
    
    def set_uuid
      if self.uuid.nil?
        self.uuid = SecureRandom.uuid
      end
    end
    
    def self.uuid
      PREFIX + SecureRandom.uuid
    end
  end
end