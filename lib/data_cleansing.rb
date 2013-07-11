require 'thread_safe'
require 'data_cleansing/version'
require 'data_cleansing/data_cleansing'

module DataCleansing
  autoload :Cleanse, 'data_cleansing/cleanse'
end

# Rails Extensions
#if defined?(Rails)
#  require 'data_cleansing/railtie'
#end

# Mongoid Extensions
#if defined?(Mongoid)
#  require 'data_cleansing/extensions/mongoid/fields'
#end
