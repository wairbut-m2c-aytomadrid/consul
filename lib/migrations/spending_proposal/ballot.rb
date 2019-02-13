require_dependency "budget"
require_dependency "budget/ballot"

class Migrations::SpendingProposal::Ballot
  include Migrations::Log

  attr_accessor :spending_proposal_ballot, :budget_investment_ballot, :represented_user

  def initialize(spending_proposal_ballot, represented_user=nil)
    @represented_user = represented_user
    @spending_proposal_ballot = spending_proposal_ballot
    @budget_investment_ballot = find_or_initialize_budget_investment_ballot
  end

  def migrate_ballot
    if budget_investment_ballot_valid?
      log(".")

      migrate_ballot_lines
    else
      log("\nError creating budget investment ballot from spending proposal ballot #{spending_proposal_ballot.id}\n")
    end
  end

  def migrate_ballot_lines
    spending_proposal_ballot.spending_proposals.each do |spending_proposal|
      budget_investment = find_budget_investment(spending_proposal)

      ballot_line = new_ballot_line(budget_investment)
      if ballot_line_valid?(ballot_line) && ballot_line.save
        log(".")
      else
        log("\nError adding spending proposal: #{spending_proposal.id} to ballot: #{budget_investment_ballot.id}\n")
      end
    end
  end

  private

    def budget
      Budget.where(slug: "2016").first
    end

    def find_budget_investment(spending_proposal)
      budget.investments.where(original_spending_proposal_id: spending_proposal.id).first
    end

    def find_or_initialize_budget_investment_ballot
      Budget::Ballot.find_or_initialize_by(budget_investment_ballot_attributes)
    end

    def budget_investment_ballot_valid?
      budget_investment_ballot.new_record? && budget_investment_ballot.save
    end

    def new_ballot_line(budget_investment)
      if budget_investment
        budget_investment_ballot.lines.new(investment: budget_investment)
      end
    end

    def ballot_line_valid?(ballot_line)
      ballot_line && ballot_line_does_not_exist?(ballot_line)
    end

    def ballot_line_does_not_exist?(ballot_line)
      budget_investment_ballot.investments.exclude?(ballot_line.investment)
    end

    def budget_investment_ballot_attributes
      {
        budget: budget,
        user: user
      }
    end

    def user
      represented_user || spending_proposal_ballot.user
    end

end
