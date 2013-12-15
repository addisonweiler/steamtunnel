Web::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true
  
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
     :address              => "smtp.gmail.com",
     :port                 => 587,
     :domain               => 'localhost:3000',
     :user_name            => 'welcome.steamtunneling@gmail.com',
     :password             => 'steamcrusher',
     :authentication       => 'plain',
     :enable_starttls_auto => true
  }
  

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
  
  # Devise config
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # Facebook
  config.facebook_app_id = 136112333735
  config.facebook_app_secret = 'a1c742b8f35266a4b5fe611a42e21bfa'
  config.facebook_app_scope = {:scope => 'offline_access,user_events,user_groups,rsvp_event'}
  
end
