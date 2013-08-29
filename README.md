data_cleansing
==============

Data Cleansing framework for Ruby with additional support for Rails and Mongoid

* http://github.com/reidmorrison/data_cleansing

## Introduction

It is important to keep internal data free of unwanted escape characters, leading
or trailing blanks and even newlines.
Similarly it would be useful to be able to attach a cleansing solution to a field
in a model and have the data cleansed transparently when required.

DataCleansing is a framework that allows any data cleansing to be applied to
specific attributes or fields. At this time it does not supply the cleaning
solutions themselves since they are usually straight forward, or so complex
that they don't tend to be too useful to others. However, over time built-in
cleansing solutions may be added. Feel free to submit any suggestions via a ticket
or pull request.

## Features

* Supports global cleansing definitions that can be associated with any Ruby,
  Rails, Mongoid, or other model
* Supports custom cleansing definitions that can be defined in-line
* A cleansing block can access the other attributes in the model while cleansing
  the current attribute
* In a cleansing block other attributes in the model can be modified at the
  same time
* Cleansers are executed in the order they are defined. As a result multiple
  cleansers can be run against the same field and the order is preserved
* Multiple cleansers can be specified for a list of attributes at the same time
* Inheritance is supported. The cleansers for parent classes are run before
  the child's cleansers
* Cleansers can be called outside of a model instance for cases where fields
  need to be cleansed before the model is created, or needs to be found
* To aid troubleshooting the before and after values of cleansed attributes
  is logged. The level of detail is fine-tuned using the log level

## ActiveRecord (ActiveModel) Features

* Passes the value of the attribute before the Rails type cast so that the
  original text can be cleansed before passing back to rails for type conversion.
  This is important for numeric and date fields where spaces and control characters
  can have undesired effects

## Examples

### Ruby Example
```ruby
require 'data_cleansing'

# Define a global cleaner
DataCleansing.register_cleaner(:strip) {|string| string.strip}

class User
  include DataCleansing::Cleanse

  attr_accessor :first_name, :last_name

  # Strip leading and trialing whitespace from first_name and last_name
  cleanse :first_name, :last_name, :cleaner => :strip
end

u = User.new
u.first_name = '    joe   '
u.last_name = "\n  black\n"
puts "Before data cleansing #{u.inspect}"
# Before data cleansing #<User:0x007fc9f1081980 @first_name="    joe   ", @last_name="\n  black\n">

u.cleanse_attributes!
puts "After data cleansing #{u.inspect}"
# After data cleansing #<User:0x007fc9f1081980 @first_name="joe", @last_name="black">
```

### Rails Example

```ruby
# Define a global cleanser
DataCleansing.register_cleaner(:strip) {|string| string.strip}

# 'users' table has the following columns :first_name, :last_name, :address1, :address2
class User < ActiveRecord::Base
  include DataCleansing::Cleanse

  # Use a global cleaner
  cleanse :first_name, :last_name, :cleaner => :strip

  # Define a once off cleaner
  cleanse :address1, :address2, :cleaner => Proc.new {|string| string.strip}

  # Automatically cleanse data before validation
  before_validation :cleanse_attributes!
end

# Create a User instance
u = User.new(:first_name => '    joe   ', :last_name => "\n  black\n", :address1 => "2632 Brown St   \n")
puts "Before data cleansing #{u.attributes.inspect}"
u.validate
puts "After data cleansing #{u.attributes.inspect}"
u.save!
```

### Advanced Ruby Example

```ruby
require 'data_cleansing'

# Define a global cleaners
DataCleansing.register_cleaner(:strip) {|string| string.strip}
DataCleansing.register_cleaner(:upcase) {|string| string.upcase}

class User
  include DataCleansing::Cleanse

  attr_accessor :first_name, :last_name, :title, :address1, :address2, :gender

  # Use a global cleaner
  cleanse :first_name, :last_name, :cleaner => :strip

  # Define a once off cleaner
  cleanse :address1, :address2, :cleaner => Proc.new {|string| string.strip}

  # Use multiple cleaners, and a custom block
  cleanse :title, :cleaner => [:strip, :upcase, Proc.new {|string| "#{string}." unless string.end_with?('.')}]

  # Change the cleansing rule based on the value of other attributes in that instance of user
  # The 'title' is retrieved from the current instance of the user
  cleanse :gender, :cleaner => [
    :strip,
    :upcase,
    Proc.new do |gender|
      if (gender == "UNKNOWN") && (title == "MR.")
        "Male"
      else
        "Female"
      end
    end
  ]
end

u = User.new
u.first_name = '    joe   '
u.last_name = "\n  black\n"
u.address1 = "2632 Brown St   \n"
u.title = "   \nmr   \n"
u.gender = " Unknown  "
puts "Before data cleansing #{u.inspect}"
# Before data cleansing #<User:0x007fdd5a83a8f8 @first_name="    joe   ", @last_name="\n  black\n", @address1="2632 Brown St   \n", @title="   \nmr   \n", @gender=" Unknown  ">

u.cleanse_attributes!
puts "After data cleansing #{u.inspect}"
# After data cleansing #<User:0x007fdd5a83a8f8 @first_name="joe", @last_name="black", @address1="2632 Brown St", @title="MR.", @gender="Male">
```

## After Cleansing

It is sometimes useful to read or write multiple fields as part of a cleansing, or
where attributes need to be manipulated automatically once they have been cleansed.
For this purpose instance methods on the model can be registered for invocation once
all the attributes have been cleansed according to their :cleanse specifications.
Multiple methods can be registered and they are called in the order they are registered.

```ruby
after_cleanse <instance_method_name>, <instance_method_name>, ...
```

Example:
```ruby
# Define a global cleanser
DataCleansing.register_cleaner(:strip) {|string| string.strip}

# 'users' table has the following columns :first_name, :last_name, :address1, :address2
class User < ActiveRecord::Base
  include DataCleansing::Cleanse

  # Use a global cleaner
  cleanse :first_name, :last_name, :cleaner => :strip

  # Define a once off cleaner
  cleanse :address1, :address2, :cleaner => Proc.new {|string| string.strip}

  # Once the above cleansing is complete call the instance method
  after_cleanse :check_address

  protected

  # Method to be called once data cleansing is complete
  def check_address
    # Move address2 to address1 if Address1 is blank and address2 has a value
    address2 = address1 if address1.blank? && !address2.blank?
  end

end

# Create a User instance
u = User.new(:first_name => '    joe   ', :last_name => "\n  black\n", :address2 => "2632 Brown St   \n")
puts "Before data cleansing #{u.attributes.inspect}"
u.cleanse_attributes!
puts "After data cleansing #{u.attributes.inspect}"
u.save!
```

## Recommendations

:data_cleanse block are ideal for cleansing a single attribute, and applying any
global or common cleansing algorithms.

Even though multiple attributes can be read or written in a single :data_cleanse
block, it is recommended to use the :after_cleanse method for working with multiple
attributes. It is much easier to read and understand the interactions between multiple
attributes in the :after_cleanse methods.

## Rails configuration

When DataCleansing is used in a Rails environment it can be configured using the
regular Rails configuration mechanisms. For example:

```ruby
module MyApplication
  class Application < Rails::Application

   # Data Cleansing Configuration

   # Attributes who's values are to be masked out during logging
   config.data_cleansing.register_masked_attributes :bank_account_number, :social_security_number

   # Optionally override the default log level
   #   Set to :trace or :debug to log all fields modified
   #   Set to :info to log only those fields which were nilled out
   #   Set to :warn or higher to disable logging of cleansing actions
   config.data_cleansing.logger.level = :info

   # Register any global cleaners
   config.data_cleansing.register_cleaner(:strip) {|string| string.strip}

  end
end
```

## Logging

DataCleansing uses SemanticLogger for logging due to it's excellent integration
with Rails and its ability to log data in it's raw form to Mongo and to files.

If running a Rails application it is recommended to install the gem
rails_semantic_logger which replaces the default Rails logger. It is however
possible to configure the semantic_logger gem to use the existing Rails logger
in a Rails initializer as follows:

```ruby
SemanticLogger.default_level = Rails.logger.level
SemanticLogger.add_appender(Rails.logger)
```

By changing the log level of DataCleansing itself the type of output for data
cleansing can be controlled:

* :trace or :debug to log all fields modified
* :info to log only those fields which were nilled out
* :warn or higher to disable logging of cleansing actions

Note:

* The logging of changes made to attributes only includes attributes cleansed
  with :data_cleanse blocks. Attributes modified within :after_cleanse methods
  are not logged

* It is not necessary to change the global log level to affect the logging detail
  level in DataCleansing. DataCleansing log level is changed independently

To change the log level, either use the Rails configuration approach, or set it
directly:

```ruby
DataCleansing.logger.level = :info
```

## Notes

* Cleaners are called in the order in which they are defined, so subsequent cleaners
  can assume that the previous cleaners have run and can therefore access or even
  modify previously cleaned attributes

## Installation

### Add to an existing Rails project

Add the following line to Gemfile

```ruby
gem 'data_cleansing'
```

Install the Gem with bundler

    bundle install

## Architecture

DataCleansing has been designed to support externalized data cleansing routines.
In this way the data cleansing routine itself can be loaded from a datastore and
applied dynamically at runtime.
Although not supported out of the box, this design allows for example for the
data cleansing routines to be stored in something like [ZooKeeper](http://zookeeper.apache.org/).
Then any changes to the data cleansing routines can be pushed out immediately to
every server that needs it.

DataCleansing is designed to support any Ruby model. In this way it can be used
in just about any ORM or DOM. For example, it currently easily supports both
Rails and Mongoid models. Some extensions have been added to support these frameworks.

For example, in Rails it obtains the raw data value before Rails has converted it.
Which is useful for cleansing integer or float fields as raw strings before Rails
tries to convert it to an integer or float.

## Dependencies

DataCleansing requires the following dependencies

* Ruby V1.8.7, V1.9.3 or V2 and greater
* Rails V2 or greater for Rails integration ( Only if Rails is being used )
* Mongoid V2 or greater for Mongoid integration ( Only if Mongoid is being used )

## Meta

* Code: `git clone git://github.com/reidmorrison/data_cleansing.git`
* Home: <https://github.com/reidmorrison/data_cleansing>
* Issues: <http://github.com/reidmorrison/data_cleansing/issues>
* Gems: <http://rubygems.org/gems/data_cleansing>

This project uses [Semantic Versioning](http://semver.org/).

## Authors

Reid Morrison :: reidmo@gmail.com :: @reidmorrison

## License

Copyright 2013 Reid Morrison

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
