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

  # piwik_tracking_code_head = "<!-- Piwik -->
  # <script type='text/javascript'>
  #   var _paq = _paq || [];
  #   _paq.push(['setDomains', ['*.decidedesa.madrid.es']]);
  #   _paq.push(['trackPageView']);
  #   _paq.push(['enableLinkTracking']);
  #   (function() {
  #     var u='//webanalytics01.madrid.es/';
  #     _paq.push(['setTrackerUrl', u+'piwik.php']);
  #     _paq.push(['setSiteId', '6']);
  #     var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
  #     g.type='text/javascript'; g.async=true; g.defer=true; g.src=u+'piwik.js'; s.parentNode.insertBefore(g,s);
  #   })();
  # </script>
  # <!-- End Piwik Code -->"
  # piwik_tracking_code_body = "<!-- Piwik -->
  # <noscript><p><img src='//webanalytics01.madrid.es/piwik.php?idsite=6' style='border:0;' alt=' /></p></noscript>
  # <!-- End Piwik Code -->"
  # Setting["html.per_page_code_head"] = piwik_tracking_code_head
  # Setting["html.per_page_code_body"] = piwik_tracking_code_body
end
