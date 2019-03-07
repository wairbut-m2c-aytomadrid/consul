require "rails_helper"
require "migrations/spending_proposal/budget"

describe Migrations::SpendingProposal::Budget do

  let!(:budget) { create(:budget, slug: "2016") }

  describe "#initialize" do

    it "initializes the budget to be migrated" do
      migration = Migrations::SpendingProposal::Budget.new

      expect(migration.budget).to eq(budget)
    end

  end

  describe "#pre_rake_tasks" do

    let!(:city_group)   { create(:budget_group, budget: budget) }
    let!(:city_heading) { create(:budget_heading, group: city_group, name: "Toda la ciudad") }

    let!(:district_group)    { create(:budget_group, budget: budget) }
    let!(:district_heading1) { create(:budget_heading, group: district_group, name: "Arganzuela") }
    let!(:district_heading2) { create(:budget_heading, group: district_group, name: "Barajas") }

    context "heading price" do

      it "updates the city heading's price" do
        migration = Migrations::SpendingProposal::Budget.new
        migration.pre_rake_tasks

        city_heading.reload
        expect(city_heading.price).to eq(24000000)
      end

      it "updates the district headings' price" do
        migration = Migrations::SpendingProposal::Budget.new
        migration.pre_rake_tasks

        district_heading1.reload
        district_heading2.reload
        expect(district_heading1.price).to eq(1556169)
        expect(district_heading2.price).to eq(433589)
      end
    end

    context "heading population" do

      it "updates the city heading's population" do
        migration = Migrations::SpendingProposal::Budget.new
        migration.pre_rake_tasks

        city_heading.reload
        expect(city_heading.population).to eq(2706401)
      end

      it "updates the district headings' population" do
        migration = Migrations::SpendingProposal::Budget.new
        migration.pre_rake_tasks

        district_heading1.reload
        district_heading2.reload
        expect(district_heading1.population).to eq(131429)
        expect(district_heading2.population).to eq(37725)
      end

    end

    context "selected investments" do

      let!(:spending_proposal1) { create(:spending_proposal, feasible: true, valuation_finished: true) }
      let!(:spending_proposal2) { create(:spending_proposal, feasible: true, valuation_finished: true) }
      let!(:spending_proposal3) { create(:spending_proposal, feasible: true, valuation_finished: false) }
      let!(:spending_proposal4) { create(:spending_proposal, feasible: false, valuation_finished: true) }

      let!(:budget_investment1) { create(:budget_investment, budget: budget, original_spending_proposal_id: spending_proposal1.id) }
      let!(:budget_investment2) { create(:budget_investment, budget: budget, original_spending_proposal_id: spending_proposal2.id) }
      let!(:budget_investment3) { create(:budget_investment, budget: budget, original_spending_proposal_id: spending_proposal3.id) }
      let!(:budget_investment4) { create(:budget_investment, budget: budget, original_spending_proposal_id: spending_proposal4.id) }

      it "marks feasible and valuation finished investments as selected" do
        migration = Migrations::SpendingProposal::Budget.new
        migration.pre_rake_tasks

        budget_investment1.reload
        budget_investment2.reload
        budget_investment3.reload
        budget_investment4.reload

        expect(budget_investment1.selected).to eq(true)
        expect(budget_investment2.selected).to eq(true)
        expect(budget_investment3.selected).to eq(false)
        expect(budget_investment4.selected).to eq(false)
      end

    end
  end

