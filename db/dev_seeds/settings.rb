section "Creating Settings" do
  Setting.reset_defaults

  Setting["email_domain_for_officials"] = "madrid.es"
  Setting.create(key: "votes_for_proposal_success", value: "100")

  Setting.create(key: "twitter_handle", value: "@decidemadrid")
  Setting.create(key: "facebook_handle", value: "decidemadrid")
  Setting.create(key: "youtube_handle", value: "decidemadrid")
  Setting.create(key: "telegram_handle", value: "decidemadrid")
  Setting.create(key: "url", value: "http://localhost:3000")

  Setting.create(key: "feature.probe.plaza", value: "true")
  Setting.create(key: "feature.human_rights.accepting", value: "true")
  Setting.create(key: "feature.human_rights.voting", value: "true")
  Setting.create(key: "feature.human_rights.closed", value: "true")
  Setting.create(key: "feature.user.skip_verification", value: "true")
  Setting.create(key: "feature.map", value: "true")

  Setting.create(key: "mailer_from_name", value: "Decide Madrid")
  Setting.create(key: "mailer_from_address", value: "noreply@madrid.es")
  Setting.create(key: "meta_title", value: "Decide Madrid")
  Setting.create(key: "meta_description", value: "Citizen Participation & Open Gov Application")
  Setting.create(key: "meta_keywords", value: "citizen participation, open government")
  Setting.create(key: "verification_offices_url", value: "http://oficinas-atencion-ciudadano.url/")
  Setting.create(key: "proposal_notification_minimum_interval_in_days", value: 0)
end
