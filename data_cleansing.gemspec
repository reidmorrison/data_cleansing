$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'data_cleansing/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'data_cleansing'
  s.version     = DataCleansing::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Reid Morrison']
  s.email       = ['reidmo@gmail.com']
  s.homepage    = 'http://github.com/reidmorrison/data_cleansing'
  s.summary     = 'Data Cleansing framework for Ruby, Rails, Mongoid and MongoMapper.'
  s.files       = Dir['lib/**/*', 'bin/*', 'LICENSE.txt', 'Rakefile', 'README.md']
  s.test_files  = Dir['test/**/*']
  s.license     = 'Apache-2.0'
  s.has_rdoc    = true
  s.add_dependency 'concurrent-ruby', '~> 1.0'
  s.add_dependency 'semantic_logger', '>= 2.0'
end
