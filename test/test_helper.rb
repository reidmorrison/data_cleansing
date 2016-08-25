$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'yaml'
require 'minitest/autorun'
require 'minitest/reporters'
require 'awesome_print'
require 'data_cleansing'

MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new

SemanticLogger.add_appender(file_name: 'test.log', formatter: :color)
SemanticLogger.default_level = :debug
