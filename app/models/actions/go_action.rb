class GoAction < Action
  def action_type
    "Go"
  end
  
  def verb
    "attended"
  end
  
  def self.for(show, person, occurred_at=nil)
    GoAction.new.tap do |go_action|
      go_action.person = person
      go_action.subject = show
      go_action.details = "attended #{show.event}"
      go_action.organization = show.organization
      go_action.occurred_at = ( occurred_at.nil? ? show.datetime : occurred_at )
    end
  end
  
  def sentence
    details
  end
end