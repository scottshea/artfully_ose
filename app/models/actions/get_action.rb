class GetAction < Action
  def subtype
    "Purchase"
  end

  def action_type
    "Get"
  end
  
  def verb
    "purchased"
  end
end