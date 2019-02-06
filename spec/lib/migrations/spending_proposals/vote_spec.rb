require "rails_helper"
require "migrations/spending_proposal/vote"

describe Migrations::SpendingProposal::Vote do

  describe "#migrate_delegated_votes" do

    it "create a represented user vote when single delegation" do
      forum = create(:forum)
      represented_user = create(:represented_user, representative: forum)
      spending_proposal = create(:spending_proposal)

      create(:vote, votable: spending_proposal, voter: forum.user)

      expect(spending_proposal.votes_for.count).to eq(1)

      Migrations::SpendingProposal::Vote.new.migrate_delegated_votes

      expect(spending_proposal.votes_for.count).to eq(2)
      expect(Vote.last.voter).to eq(represented_user)
      expect(Vote.last.votable).to eq(spending_proposal)
    end

    it "creates represented user votes when multiple delegations" do
      forum = create(:forum)
      represented_user1 = create(:represented_user, representative: forum)
      represented_user2 = create(:represented_user, representative: forum)
      spending_proposal = create(:spending_proposal)

      create(:vote, votable: spending_proposal, voter: forum.user)

      expect(spending_proposal.votes_for.count).to eq(1)

      Migrations::SpendingProposal::Vote.new.migrate_delegated_votes

      expect(spending_proposal.votes_for.count).to eq(3)
    end

    it "creates represented user votes when multiple delegations for mulitple spending proposals" do
      forum1 = create(:forum)
      forum2 = create(:forum)
      represented_user1 = create(:represented_user, representative: forum1)
      represented_user2 = create(:represented_user, representative: forum2)
      spending_proposal1 = create(:spending_proposal)
      spending_proposal2 = create(:spending_proposal)

      create(:vote, votable: spending_proposal1, voter: forum1.user)
      create(:vote, votable: spending_proposal2, voter: forum2.user)

      expect(spending_proposal1.votes_for.count).to eq(1)
      expect(spending_proposal2.votes_for.count).to eq(1)

      Migrations::SpendingProposal::Vote.new.migrate_delegated_votes

      expect(spending_proposal1.votes_for.count).to eq(2)
      expect(spending_proposal2.votes_for.count).to eq(2)
    end

    it "creates represented user votes when existing user votes" do
      forum = create(:forum)
      represented_user = create(:represented_user, representative: forum)
      spending_proposal = create(:spending_proposal)

      user = create(:user, :verified)

      create(:vote, votable: spending_proposal, voter: forum.user)
      create(:vote, votable: spending_proposal, voter: user)

      expect(spending_proposal.votes_for.count).to eq(2)

      Migrations::SpendingProposal::Vote.new.migrate_delegated_votes

      expect(spending_proposal.votes_for.count).to eq(3)
    end

    it "verifies if represented user already voted" do
      forum = create(:forum)
      represented_user = create(:represented_user, representative: forum)
      spending_proposal = create(:spending_proposal)

      create(:vote, votable: spending_proposal, voter: forum.user)
      create(:vote, votable: spending_proposal, voter: represented_user)

      expect(spending_proposal.votes_for.count).to eq(2)

      Migrations::SpendingProposal::Vote.new.migrate_delegated_votes

      expect(spending_proposal.votes_for.count).to eq(2)
    end

    it "verifies if delegated vote has already been created" do
      forum = create(:forum)
      represented_user = create(:represented_user, representative: forum)
      spending_proposal = create(:spending_proposal)

      create(:vote, votable: spending_proposal, voter: forum.user)

      expect(spending_proposal.votes_for.count).to eq(1)

      Migrations::SpendingProposal::Vote.new.migrate_delegated_votes
      Migrations::SpendingProposal::Vote.new.migrate_delegated_votes

      expect(spending_proposal.votes_for.count).to eq(2)
    end

  end

  describe "#delegated_votes" do

    it "returns delegated votes when no delegations" do
      delegated_votes = Migrations::SpendingProposal::Vote.new.delegated_votes
      expect(delegated_votes.count).to eq(0)
    end

    it "returns delegated votes when one delegation for one spending proposal" do
      forum = create(:forum)
      represented_user1 = create(:represented_user, representative: forum)
      spending_proposal = create(:spending_proposal)

      create(:vote, votable: spending_proposal, voter: forum.user)

      delegated_votes = Migrations::SpendingProposal::Vote.new.delegated_votes

      expect(delegated_votes.count).to eq(1)
      expect(delegated_votes.first[:voter]).to eq(represented_user1)
      expect(delegated_votes.first[:votable]).to eq(spending_proposal)
    end

    it "returns delegated votes when one delegations but represented user also voted" do
      forum = create(:forum)
      represented_user1 = create(:represented_user, representative: forum)
      spending_proposal = create(:spending_proposal)

      create(:vote, votable: spending_proposal, voter: forum.user)
      create(:vote, votable: spending_proposal, voter: represented_user1)

      delegated_votes = Migrations::SpendingProposal::Vote.new.delegated_votes

      expect(delegated_votes.count).to eq(0)
    end

    it "returns delegated votes when multiple delegations for one spending proposal" do
      forum = create(:forum)
      represented_user1 = create(:represented_user, representative: forum)
      represented_user2 = create(:represented_user, representative: forum)
      spending_proposal = create(:spending_proposal)

      create(:vote, votable: spending_proposal, voter: forum.user)

      delegated_votes = Migrations::SpendingProposal::Vote.new.delegated_votes
      expect(delegated_votes.count).to eq(2)

      voters = delegated_votes.collect   { |vote| vote[:voter] }
      votables = delegated_votes.collect { |vote| vote[:votable] }

      expect(voters).to include(represented_user1)
      expect(voters).to include(represented_user2)
      expect(votables).to eq([spending_proposal, spending_proposal])
    end

    it "returns delegated votes when multiple delegations for multiple spending proposal" do
      forum1 = create(:forum)
      forum2 = create(:forum)
      represented_user1 = create(:represented_user, representative: forum1)
      represented_user2 = create(:represented_user, representative: forum2)
      spending_proposal1 = create(:spending_proposal)
      spending_proposal2 = create(:spending_proposal)

      create(:vote, votable: spending_proposal1, voter: forum1.user)
      create(:vote, votable: spending_proposal2, voter: forum2.user)

      delegated_votes = Migrations::SpendingProposal::Vote.new.delegated_votes
      expect(delegated_votes.count).to eq(2)

      voters = delegated_votes.collect   { |vote| vote[:voter] }
      votables = delegated_votes.collect { |vote| vote[:votable] }

      expect(voters).to include(represented_user1)
      expect(voters).to include(represented_user2)
      expect(votables).to include(spending_proposal1)
      expect(votables).to include(spending_proposal2)
    end

  end

  describe "#create_budget_investment_votes" do

    it "creates a budget investment's vote for a corresponding spending proposal's vote" do
      spending_proposal = create(:spending_proposal)
      budget_investment = create(:budget_investment, original_spending_proposal_id: spending_proposal.id)

      spending_proposal_vote = create(:vote, votable: spending_proposal)

      Migrations::SpendingProposal::Vote.new.create_budget_investment_votes

      budget_investment_vote = budget_investment.votes_for.first

      expect(budget_investment.votes_for.count).to eq(1)
      expect(budget_investment_vote.voter).to eq(spending_proposal_vote.voter)
      expect(budget_investment_vote.votable).to eq(budget_investment)
      expect(budget_investment_vote.vote_flag).to eq(true)
    end

    it "verifies if user has already voted" do
      spending_proposal = create(:spending_proposal)
      budget_investment = create(:budget_investment, original_spending_proposal_id: spending_proposal.id)

      spending_proposal_vote = create(:vote, votable: spending_proposal)

      Migrations::SpendingProposal::Vote.new.create_budget_investment_votes
      Migrations::SpendingProposal::Vote.new.create_budget_investment_votes

      expect(budget_investment.votes_for.count).to eq(1)
    end

    it "creates budget investment's votes for all correspoding spending proposal's votes" do
      spending_proposal1 = create(:spending_proposal)
      spending_proposal2 = create(:spending_proposal)
      budget_investment1 = create(:budget_investment, original_spending_proposal_id: spending_proposal1.id)
      budget_investment2 = create(:budget_investment, original_spending_proposal_id: spending_proposal2.id)

      3.times { create(:vote, votable: spending_proposal1) }
      5.times { create(:vote, votable: spending_proposal2) }

      Migrations::SpendingProposal::Vote.new.create_budget_investment_votes

      expect(budget_investment1.votes_for.count).to eq(3)
      expect(budget_investment2.votes_for.count).to eq(5)
    end

    it "gracefully handles missing corresponding budget investment" do
      spending_proposal = create(:spending_proposal)
      spending_proposal_vote = create(:vote, votable: spending_proposal)

      expect{ Migrations::SpendingProposal::Vote.new.create_budget_investment_votes }
      .not_to raise_error
    end

  end
end
