require "rails_helper"

describe SpendingProposal do

  let(:spending_proposal) { build(:spending_proposal) }

  it "should be valid" do
    expect(spending_proposal).to be_valid
  end

  it "should not be valid without an author" do
    spending_proposal.author = nil
    expect(spending_proposal).not_to be_valid
  end

  describe "#title" do
    it "should not be valid without a title" do
      spending_proposal.title = nil
      expect(spending_proposal).not_to be_valid
    end

    it "should not be valid when very short" do
      spending_proposal.title = "abc"
      expect(spending_proposal).not_to be_valid
    end

    it "should not be valid when very long" do
      spending_proposal.title = "a" * 81
      expect(spending_proposal).not_to be_valid
    end
  end

  describe "#description" do
    it "should be sanitized" do
      spending_proposal.description = "<script>alert('danger');</script>"
      spending_proposal.valid?
      expect(spending_proposal.description).to eq("alert('danger');")
    end

    it "should be valid with allowed length" do
      spending_proposal.description = "a" * 9999
      expect(spending_proposal).to be_valid
    end

    it "should not be valid when very long" do
      spending_proposal.description = "a" * 10001
      expect(spending_proposal).not_to be_valid
    end
  end

  describe "#feasible_explanation" do
    it "should be valid if valuation not finished" do
      spending_proposal.feasible_explanation = ""
      spending_proposal.valuation_finished = false
      expect(spending_proposal).to be_valid
    end

    it "should be valid if valuation finished and feasible" do
      spending_proposal.feasible_explanation = ""
      spending_proposal.feasible = true
      spending_proposal.valuation_finished = true
      expect(spending_proposal).to be_valid
    end

    it "should not be valid if valuation finished and unfeasible" do
      spending_proposal.feasible_explanation = ""
      spending_proposal.feasible = false
      spending_proposal.valuation_finished = true
      expect(spending_proposal).not_to be_valid
    end
  end

  describe "compatible" do
    it "should return compatible spending proposals" do
      sp1 = create(:spending_proposal, compatible: true)
      sp2 = create(:spending_proposal, compatible: true)
      sp3 = create(:spending_proposal, compatible: false)

      expect(SpendingProposal.compatible).to include(sp1, sp2)
      expect(SpendingProposal.compatible).not_to include(sp3)
    end
  end

  describe "incompatible" do
    it "should return incompatible spending proposals" do
      sp1 = create(:spending_proposal, compatible: false)
      sp2 = create(:spending_proposal, compatible: false)
      sp3 = create(:spending_proposal, compatible: true)

      expect(SpendingProposal.incompatible).to include(sp1, sp2)
      expect(SpendingProposal.incompatible).not_to include(sp3)
    end
  end

  describe "dossier info" do
    describe "#feasibility" do
      it "can be feasible" do
        spending_proposal.feasible = true
        expect(spending_proposal.feasibility).to eq "feasible"
      end

      it "can be not-feasible" do
        spending_proposal.feasible = false
        expect(spending_proposal.feasibility).to eq "not_feasible"
      end

      it "can be undefined" do
        spending_proposal.feasible = nil
        expect(spending_proposal.feasibility).to eq "undefined"
      end
    end

    describe "#unfeasible?" do
      it "returns false when only not feasible" do
        spending_proposal.feasible = false
        expect(spending_proposal.unfeasible?).to eq false
      end

      it "returns false when feasible" do
        spending_proposal.feasible = true
        expect(spending_proposal.unfeasible?).to eq false
      end

      it "returns true when not feasible and valuation finished" do
        spending_proposal.feasible = false
        spending_proposal.valuation_finished = true
        expect(spending_proposal.unfeasible?).to eq true
      end
    end

    describe "#unfeasible_email_pending?" do
      let(:spending_proposal) { create(:spending_proposal) }

      it "returns true when marked as unfeasibable and valuation_finished" do
        spending_proposal.update(feasible: false, valuation_finished: true)
        expect(spending_proposal.unfeasible_email_pending?).to eq true
      end

      it "returns false when marked as feasible" do
        spending_proposal.update(feasible: true)
        expect(spending_proposal.unfeasible_email_pending?).to eq false
      end

      it "returns false when marked as feasable and valuation_finished" do
        spending_proposal.update(feasible: true, valuation_finished: true)
        expect(spending_proposal.unfeasible_email_pending?).to eq false
      end

      it "returns false when unfeasible email already sent" do
        spending_proposal.update(unfeasible_email_sent_at: 1.day.ago)
        expect(spending_proposal.unfeasible_email_pending?).to eq false
      end
    end

    describe "#send_unfeasible_email" do
      let(:spending_proposal) { create(:spending_proposal) }

      it "sets the time when the unfeasible email was sent" do
        expect(spending_proposal.unfeasible_email_sent_at).not_to be
        spending_proposal.send_unfeasible_email
        expect(spending_proposal.unfeasible_email_sent_at).to be
      end

      it "send an email" do
        expect {spending_proposal.send_unfeasible_email}.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    describe "#code" do
      let(:spending_proposal) { create(:spending_proposal) }

      it "returns the proposal id" do
        expect(spending_proposal.code).to include((spending_proposal.id).to_s)
      end

      it "returns the administrator id when assigned" do
        spending_proposal.administrator = create(:administrator)
        expect(spending_proposal.code).to include("#{spending_proposal.id}-A#{spending_proposal.administrator.id}")
      end
    end
  end

  describe "by_admin" do
    it "should return spending proposals assigned to specific administrator" do
      spending_proposal1 = create(:spending_proposal, administrator_id: 33)
      spending_proposal2 = create(:spending_proposal)

      by_admin = SpendingProposal.by_admin(33)

      expect(by_admin.size).to eq(1)
      expect(by_admin.first).to eq(spending_proposal1)
    end
  end

  describe "scopes" do
    describe "feasible" do
      it "should return all feasible spending proposals" do
        feasible_spending_proposal = create(:spending_proposal, feasible: true)
        create(:spending_proposal)

        expect(SpendingProposal.feasible).to eq [feasible_spending_proposal]
      end
    end

    describe "unfeasible" do
      it "should return all unfeasible spending proposals" do
        unfeasible_spending_proposal = create(:spending_proposal, feasible: false, valuation_finished: true)
        create(:spending_proposal, feasible: true)
        create(:spending_proposal, feasible: false)

        expect(SpendingProposal.unfeasible).to eq [unfeasible_spending_proposal]
      end
    end

    describe "not_unfeasible" do
      it "should return all not unfeasible spending proposals" do
        not_unfeasible_spending_proposal_1 = create(:spending_proposal, feasible: true)
        not_unfeasible_spending_proposal_2 = create(:spending_proposal)
        create(:spending_proposal, feasible: false)

        not_unfeasibles = SpendingProposal.not_unfeasible

        expect(not_unfeasibles.size).to eq(2)
        expect(not_unfeasibles.include?(not_unfeasible_spending_proposal_1)).to eq(true)
        expect(not_unfeasibles.include?(not_unfeasible_spending_proposal_2)).to eq(true)
      end
    end
  end

  describe "Permissions" do
    let(:user)        { create(:user, :level_two) }
    let(:luser)       { create(:user) }
    let(:district)    { create(:geozone) }
    let(:city_sp)     { create(:spending_proposal) }
    let(:district_sp) { create(:spending_proposal, geozone: district) }

    before do
      Setting["feature.spending_proposals"] = true
      Setting["feature.spending_proposal_features.voting_allowed"] = true
    end

    after do
      Setting["feature.spending_proposals"] = nil
      Setting["feature.spending_proposal_features.voting_allowed"] = nil
    end

    describe "#reason_for_not_being_votable_by" do
      it "rejects not logged in users" do
        expect(city_sp.reason_for_not_being_votable_by(nil)).to eq(:not_logged_in)
        expect(district_sp.reason_for_not_being_votable_by(nil)).to eq(:not_logged_in)
      end

      it "rejects not verified users" do
        expect(city_sp.reason_for_not_being_votable_by(luser)).to eq(:not_verified)
        expect(district_sp.reason_for_not_being_votable_by(luser)).to eq(:not_verified)
      end

      it "rejects organizations" do
        create(:organization, user: user)
        expect(city_sp.reason_for_not_being_votable_by(user)).to eq(:organization)
        expect(district_sp.reason_for_not_being_votable_by(user)).to eq(:organization)
      end

      it "rejects votes when voting is not allowed (via admin setting)" do
        Setting["feature.spending_proposal_features.voting_allowed"] = nil
        expect(city_sp.reason_for_not_being_votable_by(user)).to eq(:not_voting_allowed)
        expect(district_sp.reason_for_not_being_votable_by(user)).to eq(:not_voting_allowed)
      end

      it "accepts valid votes when voting is allowed" do
        Setting["feature.spending_proposal_features.voting_allowed"] = true
        expect(city_sp.reason_for_not_being_votable_by(user)).to be_nil
        expect(district_sp.reason_for_not_being_votable_by(user)).to be_nil

        Setting["feature.spending_proposal_features.voting_allowed"] = nil
      end

      it "rejects city wide votes if no votes left for the user"  do
        user.city_wide_spending_proposals_supported_count = 0
        expect(city_sp.reason_for_not_being_votable_by(user)).to eq(:no_city_supports_available)
      end

    describe "#sort_by_delegated_ballots_and_price" do
      let(:sp1) { create(:spending_proposal, ballot_lines_count: 5, price: 10) }
      let(:sp2) { create(:spending_proposal, ballot_lines_count: 5, price: 20) }
      let(:sp3) { create(:spending_proposal, ballot_lines_count: 7, price: 30) }

      it "rejects district wide votes if no votes left for the user"  do
        user.district_wide_spending_proposals_supported_count = 0
        expect(district_sp.reason_for_not_being_votable_by(user)).to eq(:no_district_supports_available)
      end

      it "accepts valid district votes" do
        expect(district_sp.reason_for_not_being_votable_by(user)).to be_nil
        user.supported_spending_proposals_geozone_id = district.id
        expect(district_sp.reason_for_not_being_votable_by(user)).to be_nil
      end

      it "rejects users with different and not nil district" do
        user.supported_spending_proposals_geozone_id = create(:geozone).id
        expect(district_sp.reason_for_not_being_votable_by(user)).to eq(:different_district_assigned)
      end

    end

    describe "#register_vote" do
      it "decreases a counter for city proposals" do
        expect{ city_sp.register_vote(user, true) }.to change { user.reload.city_wide_spending_proposals_supported_count }.by(-1)
      end

      it "decreases a counter for district proposals and blocks the district" do
        expect(user.supported_spending_proposals_geozone_id).to be_nil
        expect{ district_sp.register_vote(user, true) }.to change { user.reload.district_wide_spending_proposals_supported_count }.by(-1)
        expect(user.supported_spending_proposals_geozone_id).to eq(district.id)
      end

      it "does not decrease the counters if the user has already voted" do
        city_sp.register_vote(user, true)
        district_sp.register_vote(user, true)
        expect{ city_sp.register_vote(user, true) }.to change { user.reload.city_wide_spending_proposals_supported_count }.by(0)
        expect{ district_sp.register_vote(user, true) }.to change { user.reload.district_wide_spending_proposals_supported_count }.by(0)
      end
    end

    describe "#votable_by?" do
      it "allows voting on city-wide if the counter is not too low" do
        expect(city_sp.votable_by?(user)).to be
        user.city_wide_spending_proposals_supported_count = 0
        expect(city_sp.votable_by?(user)).not_to be
      end

      it "allows voting on district-wide if the counter is not too low" do
        expect(district_sp.votable_by?(user)).to be
        user.district_wide_spending_proposals_supported_count = 0
        expect(district_sp.votable_by?(user)).not_to be
      end

      it "does now allow voting if the district is already set up" do
        expect(district_sp.votable_by?(user)).to be
        user.supported_spending_proposals_geozone_id = district.id + 1
        expect(district_sp.votable_by?(user)).not_to be
      end
    end
  end

  describe "Order" do
    describe "#sort_by_confidence_score" do

      it "should order by confidence_score" do
        least_voted = create(:spending_proposal, cached_votes_up: 1)
        most_voted = create(:spending_proposal, cached_votes_up: 10)
        some_votes = create(:spending_proposal, cached_votes_up: 5)

        expect(SpendingProposal.sort_by_confidence_score.first).to eq most_voted
        expect(SpendingProposal.sort_by_confidence_score.second).to eq some_votes
        expect(SpendingProposal.sort_by_confidence_score.third).to eq least_voted
      end

      it "should order by confidence_score and then by id" do
        least_voted  = create(:spending_proposal, cached_votes_up: 1)
        most_voted   = create(:spending_proposal, cached_votes_up: 10)
        most_voted2  = create(:spending_proposal, cached_votes_up: 10)
        least_voted2 = create(:spending_proposal, cached_votes_up: 1)


        expect(SpendingProposal.sort_by_confidence_score.first).to  eq most_voted2
        expect(SpendingProposal.sort_by_confidence_score.second).to  eq most_voted
        expect(SpendingProposal.sort_by_confidence_score.third).to  eq least_voted2
        expect(SpendingProposal.sort_by_confidence_score.fourth).to  eq least_voted
      end
    end
  end

  describe "responsible_name" do
    let(:user) { create(:user, document_number: "123456") }
    let!(:spending_proposal) { create(:spending_proposal, author: user) }

    it "gets updated with the document_number" do
      expect(spending_proposal.responsible_name).to eq("123456")
    end

    it "does not get updated if the user is erased" do
      user.erase
      expect(user.erased_at).to be
      spending_proposal.touch
      expect(spending_proposal.responsible_name).to eq("123456")
    end
  end

  describe "total votes" do
    before do
      Setting["feature.spending_proposals"] = true
      Setting["feature.spending_proposal_features.voting_allowed"] = true
    end

    after do
      Setting["feature.spending_proposals"] = nil
      Setting["feature.spending_proposal_features.voting_allowed"] = nil
    end

    it "takes into account physical votes in addition to web votes" do
      sp = create(:spending_proposal)

      sp.register_vote(create(:user, :level_two), true)
      expect(sp.total_votes).to eq(1)

      sp.physical_votes = 10
      expect(sp.total_votes).to eq(11)
    end

    it "takes into account delegated votes in addition to web votes" do
      forum = create(:forum)
      sp = create(:spending_proposal)
      user = create(:user, :level_two)
      represented_user = create(:user, representative: forum)

      sp.register_vote(user, true)
      expect(sp.total_votes).to eq(1)

      sp.register_vote(forum.user, true)
      expect(sp.total_votes).to eq(2)
    end

  end

  describe "#with_supports" do
    it "should return proposals with supports" do
      sp1 = create(:spending_proposal)
      sp2 = create(:spending_proposal)
      create(:vote, votable: sp1)

      expect(SpendingProposal.with_supports).to include(sp1)
      expect(SpendingProposal.with_supports).not_to include(sp2)
    end
  end

end
