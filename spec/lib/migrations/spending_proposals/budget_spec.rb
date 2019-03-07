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
