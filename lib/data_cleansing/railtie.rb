module RubySkynet #:nodoc:
  class Railtie < Rails::Railtie #:nodoc:

    # Exposes DataCleansing configuration to the Rails application configuration.
    #
    # @example Set up configuration in the Rails app.
    #   module MyApplication
    #     class Application < Rails::Application
    #
    #       # Data Cleansing Configuration
    #
    #       # By default logging is enabled of data cleansing actions
    #       # Set to false to disable
    #       config.data_cleansing.logging_enabled = true
    #
    #       # Attributes who's values are to be masked out during logging
    #       config.data_cleansing.register_masked_attributes :bank_account_number, :social_security_number
    #
    #       # Optionally override the default log level
    #       #   Set to :trace or :debug to log all fields modified
    #       #   Set to :info to log only those fields which were nilled out
    #       #   Set to :warn or higher to disable logging of cleansing actions
    #       config.data_cleansing.logger.level = :info
    #
    #       # Register any global cleaners
    #       config.data_cleansing.register_cleaner(:strip) {|string| string.strip!}
    #
    #     end
    #   end
    config.data_cleansing = ::DataCleansing
  end
end
