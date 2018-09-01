require 'factory_bot_rails'
require 'database_cleaner'
require 'email_spec'
require 'devise'
require 'knapsack_pro'

Dir["./spec/models/concerns/*.rb"].each { |f| require f }
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }
Dir["./spec/shared/**/*.rb"].sort.each  { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.include Devise::TestHelpers, type: :controller
  config.include FactoryBot::Syntax::Methods
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)
  config.include(CommonActions)
  config.include(ActiveSupport::Testing::TimeHelpers)

  def instrument(name, example)
    ActiveSupport::Notifications.instrument name, example: example do
      yield
    end
  end

  config.before(:suite) do
    #require 'pry'
    require 'pp'
    $total_time_loading_seeds = Hash.new(0)
    $total_time_cleaning_after = Hash.new(0)
    if config.use_transactional_fixtures?
      raise(<<-MSG)
        Delete line `config.use_transactional_fixtures = true` from rails_helper.rb
        (or set it to false) to prevent uncommitted transactions being used in
        JavaScript-dependent specs.

        During testing, the app-under-test that the browser driver connects to
        uses a different database connection to the database connection used by
        the spec. The app's database connection would not be able to access
        uncommitted transaction data setup over the spec's database connection.
      MSG
    end
    #DatabaseCleaner.clean_with(:deletion)
    puts "Truncating all tables throught DBCleaner"
    puts(Benchmark.measure {
      DatabaseCleaner.clean_with(:truncation)
    })

    puts "Truncating all tables manually"
    puts(Benchmark.measure {
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE "public"."ahoy_events", "public"."budget_ballot_lines", "public"."legislation_annotations", "public"."answers", "public"."poll_ballot_sheets", "public"."local_census_records", "public"."budget_investment_milestone_translations", "public"."locks", "public"."poll_final_recounts", "public"."admin_notifications", "public"."banner_sections", "public"."banner_translations", "public"."taggings", "public"."poll_voters", "public"."newsletters", "public"."valuators", "public"."i18n_content_translations", "public"."proposal_notifications", "public"."related_contents", "public"."poll_partial_results", "public"."budget_investment_statuses", "public"."poll_officers", "public"."forums", "public"."poll_answers", "public"."map_locations", "public"."valuation_assignments", "public"."site_customization_pages", "public"."poll_question_answer_videos", "public"."probe_options", "public"."poll_officer_assignments", "public"."probe_selections", "public"."site_customization_images", "public"."settings", "public"."legislation_proposals", "public"."probes", "public"."legislation_draft_versions", "public"."budget_groups", "public"."budget_headings", "public"."budget_investment_milestones", "public"."budgets", "public"."direct_messages", "public"."flags", "public"."topics", "public"."verified_users", "public"."poll_letter_officer_logs", "public"."spending_proposals", "public"."budget_ballots", "public"."budget_polls", "public"."votes", "public"."follows", "public"."poll_recounts", "public"."budget_phases", "public"."polls", "public"."valuator_groups", "public"."comments", "public"."moderators", "public"."budget_reclassified_votes", "public"."budget_valuator_group_assignments", "public"."debates", "public"."ballots", "public"."images", "public"."redeemable_codes", "public"."web_sections", "public"."budget_valuator_assignments", "public"."organizations", "public"."poll_booths", "public"."visits", "public"."notifications", "public"."geozones", "public"."widget_cards", "public"."widget_feeds", "public"."i18n_contents", "public"."managers", "public"."poll_ballots", "public"."poll_booth_assignments", "public"."poll_question_answers", "public"."tags", "public"."annotations", "public"."activities", "public"."delayed_jobs", "public"."poll_nvotes", "public"."campaigns", "public"."failed_census_calls", "public"."geozones_polls", "public"."budget_recommendations", "public"."documents", "public"."related_content_scores", "public"."communities", "public"."signature_sheets", "public"."signatures", "public"."site_customization_content_blocks", "public"."ballot_lines", "public"."banners", "public"."volunteer_polls", "public"."administrators", "public"."legacy_legislations", "public"."poll_questions", "public"."legislation_answers", "public"."stats", "public"."identities", "public"."legislation_questions", "public"."legislation_question_options", "public"."poll_shifts", "public"."users", "public"."legislation_processes", "public"."budget_investments", "public"."proposals";')
    })

    require 'pp'
    puts 'PG config'
    pp ActiveRecord::Base.connection.execute('SHOW ALL').values
  end

  config.before do |example|
    DatabaseCleaner.strategy = :transaction
    I18n.locale = :en
    Globalize.locale = I18n.locale
    instrument "test.seed_db", example do
      start = Time.now
      load Rails.root.join('db', 'seeds.rb').to_s
      $total_time_loading_seeds[example.metadata[:type]] += Time.now - start
    end
    Setting["feature.user.skip_verification"] = nil
  end

  $times = Hash.new(0)

  ActiveSupport::Notifications.subscribe /^test./ do |name, started, finished, unique_id, data|
    $times[name] += finished - started 
  end


  config.after(:suite) do
    puts "Total time loading seeds"
    pp $total_time_loading_seeds
    puts "$times"
    pp $times
  end

  config.before(:each, type: :feature) do
    # :rack_test driver's Rack app under test shares database connection
    # with the specs, so continue to use transaction strategy for speed.
    driver_shares_db_connection_with_specs = Capybara.current_driver == :rack_test

    unless driver_shares_db_connection_with_specs
      # Driver is probably for an external browser with an app
      # under test that does *not* share a database connection with the
      # specs, so use truncation strategy.
      # TODO use pre_count
      #DatabaseCleaner.strategy = :deletion
      DatabaseCleaner.strategy = :truncation
    end
  end

  config.before(:each, :headless_chrome) do
    Capybara.current_driver  = :headless_chrome
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each, :headless_chrome) do
    Capybara.current_driver = Capybara.default_driver
  end

  config.after(:each, :nvotes) do
    page.driver.reset!
  end

  config.before(:each, type: :feature) do
    Capybara.reset_sessions!
  end

  config.before do
    DatabaseCleaner.start
  end

  config.append_after do |example|
    #Rails.logger.info ''
    #Rails.logger.info '###########'
    #Rails.logger.info 'CLEANINGGGGG'
    #Rails.logger.info '###########'
    #Rails.logger.info ''
    instrument "test.cleaning", example do 
      DatabaseCleaner.clean
      #if DatabaseCleaner.strategy != :transaction
        #start = Time.now
        #DatabaseCleaner.clean
        #$total_time_cleaning_after[DatabaseCleaner.strategy] += Time.now - start
      #end
    end
  end

  config.before(:each, type: :feature) do
    Bullet.start_request
    allow(InvisibleCaptcha).to receive(:timestamp_threshold).and_return(0)
  end

  config.after(:each, type: :feature) do
    Bullet.perform_out_of_channel_notifications if Bullet.notification?
    Bullet.end_request
  end

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  # config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  config.expect_with(:rspec) { |c| c.syntax = :expect }
end

# Parallel build helper configuration for travis
KnapsackPro::Adapters::RSpecAdapter.bind
