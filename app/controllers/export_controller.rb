class ExportController < ArtfullyOseController

  def contacts
    @organization = current_user.current_organization
    @filename = "Artfully-People-Export-#{DateTime.now.strftime("%m-%d-%y")}.csv"
    @csv_string = @organization.people.includes(:tags, :phones, :address).all.to_comma
    send_data @csv_string, :filename => @filename, :type => "text/csv", :disposition => "attachment"
  end

  def donations
    @organization = current_user.current_organization
    @filename = "Artfully-Donations-Export-#{DateTime.now.strftime("%m-%d-%y")}.csv"
    @csv_string = @organization.donations.all.to_comma(:donation)
    send_data @csv_string, :filename => @filename, :type => "text/csv", :disposition => "attachment"
  end

  def ticket_sales
    @organization = current_user.current_organization
    @filename = "Artfully-Ticket-Sales-Export-#{DateTime.now.strftime("%m-%d-%y")}.csv"
    @csv_string = @organization.ticket_sales.all.to_comma(:ticket_sale)
    send_data @csv_string, :filename => @filename, :type => "text/csv", :disposition => "attachment"
  end

end
