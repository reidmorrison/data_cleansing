$:.push File.expand_path('../lib', __FILE__)

require 'data_cleansing/version'

Gem::Specification.new do |s|
  s.name        = 'data_cleansing'
  s.version     = DataCleansing::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Reid Morrison']
  s.homepage    = 'http://github.com/reidmorrison/data_cleansing'
  s.summary     = 'Data Cleansing framework for Ruby, Rails, and Mongoid.'
  s.files       = Dir['lib/**/*', 'bin/*', 'LICENSE.txt', 'Rakefile', 'README.md']
  s.test_files  = Dir['test/**/*']
  s.license     = 'Apache-2.0'
  s.add_dependency 'concurrent-ruby', '~> 1.0'
  s.add_dependency 'semantic_logger', '>= 2.0'
end
