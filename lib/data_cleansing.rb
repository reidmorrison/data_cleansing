require 'thread_safe'
require 'semantic_logger'
require 'data_cleansing/version'
require 'data_cleansing/data_cleansing'

module DataCleansing
  autoload :Cleanse, 'data_cleansing/cleanse'
end

# Rails Extensions
if defined?(Rails)
  require 'data_cleansing/railtie'
end
