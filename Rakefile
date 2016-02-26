require 'rake/clean'
require 'rake/testtask'

require_relative 'lib/data_cleansing/version'

task :gem do
  system 'gem build data_cleansing.gemspec'
end

task publish: :gem do
  system "git tag -a v#{DataCleansing::VERSION} -m 'Tagging #{DataCleansing::VERSION}'"
  system 'git push --tags'
  system "gem push data_cleansing-#{DataCleansing::VERSION}.gem"
  system "rm data_cleansing-#{DataCleansing::VERSION}.gem"
end

desc 'Run Test Suite'
task :test do
  Rake::TestTask.new(:functional) do |t|
    t.test_files = FileList['test/**/*_test.rb']
    t.verbose    = true
  end

  Rake::Task['functional'].invoke
end

task default: :test
