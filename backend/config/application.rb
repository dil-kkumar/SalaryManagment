require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_dispatch/railtie'

Bundler.require(*Rails.groups)

module SalaryManagement
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    config.time_zone = 'UTC'
    config.active_record.schema_format = :ruby

    # Allow all origins in development; override via CORS_ORIGINS in production
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins ENV.fetch('CORS_ORIGINS', '*')
        resource '*',
          headers: :any,
          methods: %i[get post put patch delete options head],
          expose: %w[X-Total-Count]
      end
    end
  end
end
