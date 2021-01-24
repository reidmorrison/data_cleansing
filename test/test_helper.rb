ENV["RAILS_ENV"] = "test"

require "active_record"
require "minitest/autorun"
require "data_cleansing"
require "amazing_print"

SemanticLogger.add_appender(file_name: "test.log", formatter: :color)
SemanticLogger.default_level = :debug
