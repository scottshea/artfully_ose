class SaleSearch

  attr_reader :start, :stop
  attr_reader :organization, :event, :show

  def initialize(terms)
    @organization = terms[:organization]
    @event        = terms[:event]
    @show         = terms[:show]
    @start        = start_with(terms[:start])
    @stop         = stop_with(terms[:stop])

    @results = yield(results) if block_given?
  end

  def results
    @results ||= Order.sale_search(self).select(&:has_ticket?)
  end

  private

  def start_with(start)
    start.present? ? DateTime.parse(start) : default_start
  end

  def stop_with(stop)
    stop.present? ? DateTime.parse(stop) + 1.day - 1.minute : default_stop
  end

  def default_start
    DateTime.now.in_time_zone(@organization.time_zone).beginning_of_month
  end

  def default_stop
    DateTime.now.in_time_zone(@organization.time_zone).end_of_day
  end
end
