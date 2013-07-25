module RubySkynet #:nodoc:
  class Railtie < Rails::Railtie #:nodoc:

    # Exposes DataCleansing configuration to the Rails application configuration.
    #
    # @example Set up configuration in the Rails app.
    #   module MyApplication
    #     class Application < Rails::Application
    #       config.data_cleansing.masked_attributes :bank_account_number, :social_security_number
    #       config.data_cleansing.cleansing_log_level :info
    #       config.data_cleansing.register_cleaner(:strip) {|string| string.strip!}
    #     end
    #   end
    config.data_cleansing = ::DataCleansing
  end
end
