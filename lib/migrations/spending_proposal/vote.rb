class Migrations::SpendingProposal::Vote

  def migrate_delegated_votes
    delegated_votes.each do |delegated_vote|
      create_vote(delegated_vote)
    end
  end

  def create_vote(delegated_vote)
    vote_attributes = {
      voter: delegated_vote[:voter],
      votable: delegated_vote[:votable],
      delegated: true
    }
    Vote.create!(vote_attributes)
  end

  def delegated_votes
    representative_votes.map do |vote|
      represented_user_votes(vote)
    end.flatten
  end

  def representative_votes
    Vote.representative_votes
  end

  def represented_user_votes(vote)
    representative = vote.voter.forum
    spending_proposal = vote.votable

    representative.represented_users.map do |represented_user|
      represented_user_vote(represented_user, spending_proposal)
    end.compact
  end

  def represented_user_vote(represented_user, spending_proposal)
    unless represented_user.voted_for?(spending_proposal)
      { voter: represented_user,
        votable: spending_proposal }
    end
  end

end
