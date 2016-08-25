source 'https://rubygems.org'

gem 'rake'
gem 'minitest'
gem 'minitest-reporters'
gem 'awesome_print'

gem 'sqlite3', platform: :ruby

platforms :jruby do
  gem 'jdbc-sqlite3'
  gem 'activerecord-jdbcsqlite3-adapter'
end
