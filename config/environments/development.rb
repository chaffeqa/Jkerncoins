KernCoinProject::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false
  config.cache_store = :dalli_store,
                      (ENV["MEMCACHIER_SERVERS"] || "").split(","),
                      {
                        :username => ENV["MEMCACHIER_USERNAME"],
                        :password => ENV["MEMCACHIER_PASSWORD"],
                        :namespace => 'jkerncoins', :expires_in => 20.days, :compress => true
                      }

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = true # NOTE: was true in SliceHost

  config.serve_static_assets = true

  # Don't care if the mailer can't send
#  config.action_mailer.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log
end

