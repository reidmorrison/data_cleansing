lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rubygems'
require 'rubygems/package'
require 'rake/clean'
require 'rake/testtask'
require 'date'
require 'data_cleansing/version'

desc "Build gem"
task :gem  do |t|
  gemspec = Gem::Specification.new do |s|
    s.name        = 'data_cleansing'
    s.version     = DataCleansing::VERSION
    s.platform    = Gem::Platform::RUBY
    s.authors     = ['Reid Morrison']
    s.email       = ['reidmo@gmail.com']
    s.homepage    = 'https://github.com/ClarityServices/data_cleansing'
    s.date        = Date.today.to_s
    s.summary     = "Data Cleansing framework for Ruby, and Ruby on Rails"
    s.description = "Data Cleansing framework for Ruby with additional support for Rails and Mongoid"
    s.files       = FileList["./**/*"].exclude(/.gem$/, /.log$/,/^nbproject/).map{|f| f.sub(/^\.\//, '')}
    s.license     = "Apache License V2.0"
    s.has_rdoc    = true
    s.add_dependency 'thread_safe'
    s.add_dependency 'semantic_logger'
  end
  Gem::Package.build gemspec
end

desc "Run Test Suite"
task :test do
  Rake::TestTask.new(:functional) do |t|
    t.test_files = FileList['test/*_test.rb']
    t.verbose    = true
  end

  Rake::Task['functional'].invoke
end
