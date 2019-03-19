require "rails_helper"

feature "Admin spending proposals" do

  background do
    skip "because spending proposals is no longer in use at madrid :)"
    Setting["feature.spending_proposals"] = true
    Setting["feature.spending_proposal_features.voting_allowed"] = true
    admin = create(:administrator)
    login_as(admin.user)
  end

  after do
    Setting["feature.spending_proposals"] = nil
    Setting["feature.spending_proposal_features.voting_allowed"] = nil
  end

  context "Feature flag" do

    scenario "Disabled with a feature flag" do
      Setting["feature.spending_proposals"] = nil
      expect{ visit admin_spending_proposals_path }.to raise_exception(FeatureFlags::FeatureDisabled)
    end

  end

  context "Index" do

    background do
      Setting["feature.spending_proposal_features.valuation_allowed"] = true
    end

    scenario "Displaying spending proposals" do
      spending_proposal = create(:spending_proposal, cached_votes_up: 10, physical_votes: 20)
      visit admin_spending_proposals_path

      expect(page).to have_content(spending_proposal.title)
      expect(page).to have_css(".total-votes", text: 30)
    end

    scenario "Displaying assignments info" do
      spending_proposal1 = create(:spending_proposal)
      spending_proposal2 = create(:spending_proposal)
      spending_proposal3 = create(:spending_proposal)

      valuator1 = create(:valuator, user: create(:user, username: "Olga"), description: "Valuator Olga")
      valuator2 = create(:valuator, user: create(:user, username: "Miriam"), description: "Valuator Miriam")
      admin = create(:administrator, user: create(:user, username: "Gema"))

      spending_proposal1.valuators << valuator1
      spending_proposal2.valuator_ids = [valuator1.id, valuator2.id]
      spending_proposal3.update(administrator_id: admin.id)

      visit admin_spending_proposals_path

      within("#spending_proposal_#{spending_proposal1.id}") do
        expect(page).to have_content("No admin assigned")
        expect(page).to have_content("Valuator Olga")
      end

      within("#spending_proposal_#{spending_proposal2.id}") do
        expect(page).to have_content("No admin assigned")
        expect(page).to have_content("Valuator Olga")
        expect(page).to have_content("Valuator Miriam")
      end

      within("#spending_proposal_#{spending_proposal3.id}") do
        expect(page).to have_content("Gema")
        expect(page).to have_content("No valuators assigned")
      end
    end

    scenario "Filtering by geozone", :js do
      geozone = create(:geozone, name: "District 9")
      create(:spending_proposal, title: "Realocate visitors", geozone: geozone)
      create(:spending_proposal, title: "Destroy the city")

      visit admin_spending_proposals_path
      expect(page).to have_link("Realocate visitors")
      expect(page).to have_link("Destroy the city")

      select "All city", from: "geozone_id"

      expect(page).to have_link("Destroy the city")
      expect(page).not_to have_link("Realocate visitors")

      select "All zones", from: "geozone_id"
      expect(page).to have_link("Realocate visitors")
      expect(page).to have_link("Destroy the city")

      select "District 9", from: "geozone_id"

      expect(page).not_to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")

      click_link("Realocate visitors")
      click_link("Back")

      expect(page).not_to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")

      click_link("Realocate visitors")
      click_link("Edit classification")
      expect(page).to have_button("Update")
      click_link("Back")
      expect(page).not_to have_button("Update")
      expect(page).to have_link("Back")
      click_link("Back")

      expect(page).not_to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")
    end

    scenario "Filtering by admin", :js do
      user = create(:user, username: "Admin 1")
      administrator = create(:administrator, user: user)

      create(:spending_proposal, title: "Realocate visitors", administrator: administrator)
      create(:spending_proposal, title: "Destroy the city")

      visit admin_spending_proposals_path
      expect(page).to have_link("Realocate visitors")
      expect(page).to have_link("Destroy the city")

      select "Admin 1", from: "administrator_id"

      expect(page).to have_content("There is 1 investment project")
      expect(page).not_to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")

      select "All administrators", from: "administrator_id"

      expect(page).to have_content("There are 2 investment projects")
      expect(page).to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")

      select "Admin 1", from: "administrator_id"
      expect(page).to have_content("There is 1 investment project")
      click_link("Realocate visitors")
      click_link("Back")

      expect(page).to have_content("There is 1 investment project")
      expect(page).not_to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")

      click_link("Realocate visitors")
      click_link("Edit classification")
      expect(page).to have_button("Update")
      expect(page).to have_link("Back")
      click_link("Back")
      expect(page).not_to have_button("Update")
      expect(page).to have_link("Back")
      click_link("Back")

      expect(page).to have_content("There is 1 investment project")
      expect(page).not_to have_link("Destroy the city")
      expect(page).to have_link("Realocate visitors")

    end

    scenario "Current filter is properly highlighted" do
      filters_links = {"valuation_open" => "Open",
                       "without_admin" => "Without assigned admin",
                       "managed" => "Managed",
                       "valuating" => "Under valuation",
                       "valuation_finished" => "Valuation finished",
                       "all" => "All"}

      visit admin_spending_proposals_path

      expect(page).not_to have_link(filters_links.values.first)
      filters_links.keys.drop(1).each { |filter| expect(page).to have_link(filters_links[filter]) }

      filters_links.each_pair do |current_filter, link|
        visit admin_spending_proposals_path(filter: current_filter)

        expect(page).not_to have_link(link)

        (filters_links.keys - [current_filter]).each do |filter|
          expect(page).to have_link(filters_links[filter])
        end
      end
    end

    scenario "Filtering by assignment status" do
      assigned = create(:spending_proposal, title: "Assigned idea", administrator: create(:administrator))
      valuating = create(:spending_proposal, title: "Evaluating...")
      valuating.valuators << create(:valuator)

      visit admin_spending_proposals_path(filter: "valuation_open")

      expect(page).to have_content("Assigned idea")
      expect(page).to have_content("Evaluating...")

      visit admin_spending_proposals_path(filter: "without_admin")

      expect(page).to have_content("Evaluating...")
      expect(page).not_to have_content("Assigned idea")

      visit admin_spending_proposals_path(filter: "managed")

      expect(page).to have_content("Assigned idea")
      expect(page).not_to have_content("Evaluating...")
    end

    scenario "Filtering by valuation status" do
      valuating = create(:spending_proposal, title: "Ongoing valuation")
      valuated = create(:spending_proposal, title: "Old idea", valuation_finished: true)
      valuating.valuators << create(:valuator)
      valuated.valuators << create(:valuator)

      visit admin_spending_proposals_path(filter: "valuation_open")

      expect(page).to have_content("Ongoing valuation")
      expect(page).not_to have_content("Old idea")

      visit admin_spending_proposals_path(filter: "valuating")

      expect(page).to have_content("Ongoing valuation")
      expect(page).not_to have_content("Old idea")

      visit admin_spending_proposals_path(filter: "valuation_finished")

      expect(page).not_to have_content("Ongoing valuation")
      expect(page).to have_content("Old idea")

      visit admin_spending_proposals_path(filter: "all")
      expect(page).to have_content("Ongoing valuation")
      expect(page).to have_content("Old idea")
    end

    scenario "Filtering by tag" do
      create(:spending_proposal, title: "Educate the children", tag_list: "Education")
      create(:spending_proposal, title: "More schools",         tag_list: "Education")
      create(:spending_proposal, title: "More hospitals",       tag_list: "Health")

      visit admin_spending_proposals_path

      expect(page).to have_css(".spending_proposal", count: 3)
      expect(page).to have_content("Educate the children")
      expect(page).to have_content("More schools")
      expect(page).to have_content("More hospitals")

      visit admin_spending_proposals_path(tag_name: "Education")

      expect(page).not_to have_content("More hospitals")
      expect(page).to have_css(".spending_proposal", count: 2)
      expect(page).to have_content("Educate the children")
      expect(page).to have_content("More schools")

      click_link("Educate the children")
      click_link("Back")

      expect(page).not_to have_content("More hospitals")
      expect(page).to have_content("Educate the children")
      expect(page).to have_content("More schools")

      click_link("Educate the children")
      click_link("Edit classification")
      expect(page).to have_button("Update")
      click_link("Back")
      expect(page).not_to have_button("Update")
      click_link("Back")

      expect(page).not_to have_content("More hospitals")
      expect(page).to have_content("Educate the children")
      expect(page).to have_content("More schools")
    end

    context "Limiting the number of proposals" do
      scenario "Limiting by geozone", :js do
        california = create(:geozone)
        new_york   = create(:geozone)

        [2, 3, 5, 10, 20, 99].each do |votes|
          create(:spending_proposal, geozone: california, cached_votes_up: votes, title: "Cali with #{votes} supports")
          create(:spending_proposal, geozone: new_york, cached_votes_up: votes, title: "NY voted #{votes} times")
        end

        visit admin_spending_proposals_path

        [2, 3, 5, 10, 20, 99].each do |votes|
          expect(page).to have_link "Cali with #{votes} supports"
          expect(page).to have_link "NY voted #{votes} times"
        end

        select "5", from: "max_per_geozone"

        expect(page).to have_content("There are 10 investment projects")
        expect(page).not_to have_link "Cali with 2 supports"
        expect(page).not_to have_link "NY voted 2 times"
      end

      scenario "Limiting the proposals with no geozone", :js do
        [2, 3, 5, 10, 20, 99].each do |votes|
          create(:spending_proposal, cached_votes_up: votes, title: "#{votes} supports!")
        end

        visit admin_spending_proposals_path

        [2, 3, 5, 10, 20, 99].each do |votes|
          expect(page).to have_link "#{votes} supports!"
        end

        select "5", from: "max_for_no_geozone"

        expect(page).to have_content("There are 5 investment projects")
        expect(page).not_to have_link "2 supports!"
      end

      scenario "Limiting both", :js do
        skane = create(:geozone)

        [10, 20, 99].each do |votes|
          create(:spending_proposal, geozone: skane, cached_votes_up: votes, title: "Skane with #{votes} supports")
          create(:spending_proposal, cached_votes_up: votes, title: "No geozone, #{votes} supports")
        end

        visit admin_spending_proposals_path

        [10, 20, 99].each do |votes|
          expect(page).to have_link "Skane with #{votes} supports"
          expect(page).to have_link "No geozone, #{votes} supports"
        end

        visit admin_spending_proposals_path(max_for_no_geozone: 2, max_per_geozone: 1)

        expect(page).to have_content("There are 3 investment projects")
        expect(page).to have_link "Skane with 99 supports"
        expect(page).not_to have_link "Skane with 20 supports"
        expect(page).not_to have_link "Skane with 10 supports"
        expect(page).to have_link "No geozone, 99 supports"
        expect(page).to have_link "No geozone, 20 supports"
        expect(page).not_to have_link "No geozone, 10 supports"
      end
    end

  end

  scenario "Show" do
    administrator = create(:administrator, user: create(:user, username: "Ana", email: "ana@admins.org"))
    valuator = create(:valuator, user: create(:user, username: "Rachel", email: "rachel@valuators.org"))
    spending_proposal = create(:spending_proposal,
                                geozone: create(:geozone),
                                association_name: "People of the neighbourhood",
                                price: 1234,
                                price_first_year: 1000,
                                feasible: false,
                                feasible_explanation: "It is impossible",
                                administrator: administrator)
    spending_proposal.valuators << valuator

    visit admin_spending_proposals_path

    click_link spending_proposal.title

    expect(page).to have_content(spending_proposal.title)
    expect(page).to have_content(spending_proposal.description)
    expect(page).to have_content(spending_proposal.author.name)
    expect(page).to have_content(spending_proposal.association_name)
    expect(page).to have_content(spending_proposal.geozone.name)
    expect(page).to have_content("1234")
    expect(page).to have_content("1000")
    expect(page).to have_content("Not feasible")
    expect(page).to have_content("It is impossible")
    expect(page).to have_content("Ana (ana@admins.org)")

    within("#assigned_valuators") do
      expect(page).to have_content("Rachel (rachel@valuators.org)")
    end
  end

  context "Results" do

    context "Diplays proposals ordered by ballot_lines_count" do

      background do
        @california = create(:geozone)

        @proposal1 = create(:spending_proposal, :finished, :feasible, price: 10, ballot_lines_count: 20, geozone: nil)
        @proposal2 = create(:spending_proposal, :finished, :feasible, price: 10, ballot_lines_count: 60, geozone: nil)
        @proposal3 = create(:spending_proposal, :finished, :feasible, price: 10, ballot_lines_count: 40, geozone: nil)
        @proposal4 = create(:spending_proposal, :finished, :feasible, price: 10, ballot_lines_count: 33, geozone: @california)
        @proposal5 = create(:spending_proposal, :finished, :feasible, price: 10, ballot_lines_count: 99, geozone: @california)
        @proposal6 = create(:spending_proposal, :finished, :feasible, price: 10, ballot_lines_count: 11, geozone: @california)
        @proposal7 = create(:spending_proposal, :finished, :feasible, price: 10, ballot_lines_count: 100, geozone: create(:geozone))
      end

      scenario "Spending proposals with no geozone" do
        visit results_admin_spending_proposals_path

        expect(page).to have_content "Current final voting ranking"

        within("#spending-proposals-results") do
          expect(page).to have_content @proposal1.title
          expect(page).to have_content @proposal2.title
          expect(page).to have_content @proposal3.title
          expect(page).not_to have_content @proposal4.title
          expect(page).not_to have_content @proposal5.title
          expect(page).not_to have_content @proposal6.title
          expect(page).not_to have_content @proposal7.title

          within("#spending_proposal_#{@proposal1.id}") { expect(page).to have_content "20" }
          within("#spending_proposal_#{@proposal2.id}") { expect(page).to have_content "60" }
          within("#spending_proposal_#{@proposal3.id}") { expect(page).to have_content "40" }

          expect(@proposal2.title).to appear_before(@proposal3.title)
          expect(@proposal3.title).to appear_before(@proposal1.title)
        end
      end

      scenario "Geozoned spending proposals" do
        visit results_admin_spending_proposals_path(geozone_id: @california.id)

        within("#spending-proposals-results") do
          expect(page).not_to have_content @proposal1.title
          expect(page).not_to have_content @proposal2.title
          expect(page).not_to have_content @proposal3.title
          expect(page).to have_content @proposal4.title
          expect(page).to have_content @proposal5.title
          expect(page).to have_content @proposal6.title
          expect(page).not_to have_content @proposal7.title

          expect(@proposal5.title).to appear_before(@proposal4.title)
          expect(@proposal4.title).to appear_before(@proposal6.title)
        end
      end

      context "Compatible spending proposals" do

        scenario "Include compatible spending proposals in results" do
          compatible_proposal1 = create(:spending_proposal, :finished, :feasible, price: 10, compatible: true)
          compatible_proposal2 = create(:spending_proposal, :finished, :feasible, price: 10, compatible: true)

          incompatible_proposal = create(:spending_proposal, :finished, :feasible, price: 10, compatible: false)

          visit results_admin_spending_proposals_path(geozone_id: nil)

          within("#spending-proposals-results") do
            expect(page).to have_content compatible_proposal1.title
            expect(page).to have_content compatible_proposal2.title

            expect(page).not_to have_content incompatible_proposal.title
          end
        end

        scenario "Display incompatible spending proposals after results" do
          incompatible_proposal1  = create(:spending_proposal, :finished, :feasible, price: 10, compatible: false)
          incompatible_proposal2 = create(:spending_proposal, :finished, :feasible, price: 10, compatible: false)

          compatible_proposal = create(:spending_proposal, :finished, :feasible, price: 10, compatible: true)

          visit results_admin_spending_proposals_path(geozone_id: nil)

          within("#incompatible-spending-proposals") do
            expect(page).to have_content incompatible_proposal1.title
            expect(page).to have_content incompatible_proposal2.title

            expect(page).not_to have_content compatible_proposal.title
          end
        end

      end

      scenario "Delegated votes affecting the result" do
        forum = create(:forum)
        create_list(:user, 30, :level_two, representative: forum)
        forum.ballot.spending_proposals << @proposal3

        visit results_admin_spending_proposals_path

        expect(page).to have_content @proposal1.title
        expect(page).to have_content @proposal2.title
        expect(page).to have_content @proposal3.title

        within("#spending_proposal_#{@proposal1.id}") { expect(page).to have_content "20" }
        within("#spending_proposal_#{@proposal2.id}") { expect(page).to have_content "60" }
        within("#spending_proposal_#{@proposal3.id}") { expect(page).to have_content "70" }

        expect(@proposal3.title).to appear_before(@proposal2.title)
        expect(@proposal2.title).to appear_before(@proposal1.title)
      end
    end

    scenario "Displays only finished feasible spending proposals" do
      california = create(:geozone)

      proposal1 = create(:spending_proposal, :finished, :feasible, price: 10, ballot_lines_count: 20, geozone: california)
      proposal2 = create(:spending_proposal, :finished, price: 10, ballot_lines_count: 60, geozone: california)
      proposal3 = create(:spending_proposal, :feasible, price: 10, ballot_lines_count: 40, geozone: california)
      proposal4 = create(:spending_proposal, price: 10, ballot_lines_count: 40, geozone: california)

      visit results_admin_spending_proposals_path(geozone_id: california.id)

      within("#spending-proposals-results") do
        expect(page).to have_content proposal1.title
        expect(page).not_to have_content proposal2.title
        expect(page).not_to have_content proposal3.title
        expect(page).not_to have_content proposal4.title
      end
    end

    scenario "Highlights winner candidates (within budget), if tied most expensive first" do
      centro = create(:geozone, name: "Centro") #budget: 1353966

      proposal1 = create(:spending_proposal, :finished, :feasible, price: 1000000, ballot_lines_count: 999, geozone: centro)
      proposal2 = create(:spending_proposal, :finished, :feasible, price:  900000, ballot_lines_count: 888, geozone: centro)
      proposal3 = create(:spending_proposal, :finished, :feasible, price:  700000, ballot_lines_count: 777, geozone: centro)
      proposal4 = create(:spending_proposal, :finished, :feasible, price:  350000, ballot_lines_count: 666, geozone: centro)
      proposal5 = create(:spending_proposal, :finished, :feasible, price:  320000, ballot_lines_count: 666, geozone: centro)
      proposal6 = create(:spending_proposal, :finished, :feasible, price:      10, ballot_lines_count: 555, geozone: centro)

      visit results_admin_spending_proposals_path(geozone_id: centro.id)

      within("#spending-proposals-results") do
        expect(proposal1.title).to appear_before(proposal2.title)
        expect(proposal2.title).to appear_before(proposal3.title)
        expect(proposal3.title).to appear_before(proposal4.title)
        expect(proposal4.title).to appear_before(proposal5.title)
        expect(proposal5.title).to appear_before(proposal6.title)

        expect(page).to have_css("#spending_proposal_#{proposal1.id}.success")
        expect(page).to have_css("#spending_proposal_#{proposal4.id}.success")
        expect(page).to have_css("#spending_proposal_#{proposal6.id}.success")
        expect(page).not_to have_css("#spending_proposal_#{proposal2.id}.success")
        expect(page).not_to have_css("#spending_proposal_#{proposal3.id}.success")
        expect(page).not_to have_css("#spending_proposal_#{proposal5.id}.success")
      end
    end

    scenario "Display winner emails" do
      centro = create(:geozone, name: "Centro") #budget: 1353966

      proposal1 = create(:spending_proposal, :finished, :feasible, price: 1000000, ballot_lines_count: 999, geozone: centro)
      proposal2 = create(:spending_proposal, :finished, :feasible, price:  900000, ballot_lines_count: 888, geozone: centro)
      proposal3 = create(:spending_proposal, :finished, :feasible, price:  700000, ballot_lines_count: 777, geozone: centro)
      proposal4 = create(:spending_proposal, :finished, :feasible, price:  350000, ballot_lines_count: 666, geozone: centro)
      proposal5 = create(:spending_proposal, :finished, :feasible, price:  320000, ballot_lines_count: 666, geozone: centro)
      proposal6 = create(:spending_proposal, :finished, :feasible, price:      10, ballot_lines_count: 555, geozone: centro)

      visit results_admin_spending_proposals_path(geozone_id: centro.id)

      within("#spending-proposals-winners") do
        expect(page).to have_content(proposal1.author.email)
        expect(page).to have_content(proposal4.author.email)
        expect(page).to have_content(proposal6.author.email)

        expect(page).not_to have_content(proposal2.author.email)
        expect(page).not_to have_content(proposal3.author.email)
        expect(page).not_to have_content(proposal5.author.email)
      end
    end

    scenario "Display winner contact information" do
      centro = create(:geozone, name: "Centro") #budget: 1353966

      user1 = create(:user, confirmed_phone: "12345678")
      user2 = create(:user, confirmed_phone: "22345678")
      user3 = create(:user, confirmed_phone: "32345678")
      user4 = create(:user, confirmed_phone: "42345678")
      user5 = create(:user, confirmed_phone: "52345678")
      user6 = create(:user, confirmed_phone: "62345678")

      proposal1 = create(:spending_proposal, :finished, :feasible, author: user1, price: 1000000, ballot_lines_count: 999, geozone: centro)
      proposal2 = create(:spending_proposal, :finished, :feasible, author: user2, price:  900000, ballot_lines_count: 888, geozone: centro)
      proposal3 = create(:spending_proposal, :finished, :feasible, author: user3, price:  700000, ballot_lines_count: 777, geozone: centro)
      proposal4 = create(:spending_proposal, :finished, :feasible, author: user4, price:  350000, ballot_lines_count: 666, geozone: centro)
      proposal5 = create(:spending_proposal, :finished, :feasible, author: user5, price:  320000, ballot_lines_count: 666, geozone: centro)
      proposal6 = create(:spending_proposal, :finished, :feasible, author: user6, price:      10, ballot_lines_count: 555, geozone: centro)

      visit results_admin_spending_proposals_path(geozone_id: centro.id)

      within("#spending-proposals-results") do
        expect(page).to have_content(proposal1.author.confirmed_phone)
        expect(page).to have_content(proposal4.author.confirmed_phone)
        expect(page).to have_content(proposal6.author.confirmed_phone)

        expect(page).not_to have_content(proposal2.author.confirmed_phone)
        expect(page).not_to have_content(proposal3.author.confirmed_phone)
        expect(page).not_to have_content(proposal5.author.confirmed_phone)
      end

      within("#spending-proposals-results") do
        expect(page).to have_link proposal1.author.name, href: admin_user_path(proposal1.author)
        expect(page).to have_link proposal4.author.name, href: admin_user_path(proposal4.author)
        expect(page).to have_link proposal6.author.name, href: admin_user_path(proposal6.author)

        expect(page).not_to have_link proposal2.author.name
        expect(page).not_to have_link proposal3.author.name
        expect(page).not_to have_link proposal5.author.name
      end
    end
  end

end
