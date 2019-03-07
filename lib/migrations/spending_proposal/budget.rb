class Migrations::SpendingProposal::Budget
  attr_accessor :budget

  def initialize
    @budget = find_budget
  end

end
