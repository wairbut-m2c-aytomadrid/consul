class Migrations::SpendingProposal::Vote
  include Migrations::Log

  def create_budget_investment_votes
    spending_proposal_votes.each do |vote|
      create_budget_invesment_vote(vote)
      log(".")
    end
  end

  private

    def spending_proposal_votes
      Vote.where(votable: SpendingProposal.all)
    end

    def find_budget_investment(spending_proposal)
      Budget::Investment.where(original_spending_proposal_id: spending_proposal.id).first
    end

    def create_budget_invesment_vote(vote)
      budget_investment = find_budget_investment(vote.votable)
      if budget_investment
        budget_investment.vote_by(voter: vote.voter, vote: "yes")
      end
    end

end
