Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.public_file_server.enabled = true
  config.show_exceptions = false
  config.log_level = :fatal
end
