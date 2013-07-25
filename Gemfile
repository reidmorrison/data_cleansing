source 'https://rubygems.org'
gem 'thread_safe'
gem 'semantic_logger'

group :test do
  gem "shoulda"

  gem "activerecord"
  gem 'sqlite3', :platform => :ruby

  platforms :jruby do
    gem 'jdbc-sqlite3'
    gem 'activerecord-jdbcsqlite3-adapter'
  end

  gem "mongoid"
end

group :develop do
  gem 'awesome_print'
end