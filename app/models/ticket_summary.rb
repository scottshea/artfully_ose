class TicketSummary
  attr_accessor :rows
  
  def initialize
    @rows = []
  end

  def row_for_this(show)
    @rows.find {|row| row.show == show} || (@rows << TicketSummary::Row.new).last
  end
  
  def <<(ticket)
    row_for_this(ticket.show) << ticket
  end
  
  class TicketSummary::Row
    attr_accessor :show, :tickets
    
    def initialize
      @tickets = []
    end
    
    def <<(ticket)
      @tickets << ticket
      @show = ticket.show
      self
    end
  end
end