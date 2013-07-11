data_cleansing
==============

Data Cleansing solution for Ruby with additional support for Rails and Mongoid

* http://github.com/ClarityServices/data_cleansing

## Introduction

It is important to keep internal data free of unwanted escape characters, leading
or trailing blanks and even newlines.
Similarly it would be useful to be able to attach a cleansing solution to a field
in a model and have the data cleansed transparently when required.

DataCleansing is a framework that allows any data cleansing to be applied to
specific attributes or fields. At this time it does not supply the cleaning
solutions themselves since they are usually straight forward, or so complex
that they don't tend to be too usefull to others. However, over time built-in
cleansing solutions may be added. Feel free to submit any suggestions via a ticket
or pull request.

## Features

* Supports global cleansing definitions that can be associated with any Ruby,
  Rails, Mongoid, or other model.
* Supports custom cleansing definitions for a single attribute

## Examples

### Ruby Example

```ruby
class User
  include DataCleansing::Cleanse

  attr_accessor :first_name, :last_name, :address1, :address2

  # Use a global cleaner
  cleanse :first_name, :last_name, :cleaner => :strip

  # Define a once off cleaner
  cleanse :address1, :address2, :cleaner => Proc.new {|string| string.strip!}
end

# Define a global cleanser
DataCleansing.register_cleaner(:strip) {|string, params, object| string.strip!}

u = User.new
u.first_name = '    joe   '
u.last_name = "\n  black\n"
u.address1 = "2632 Brown St   \n"
puts "Before data cleansing #{u.inspect}"
u.cleanse_attributes!
puts "After data cleansing #{u.inspect}"
```

### Rails Example

To encrypt a field in a Mongoid document, just add ":encrypted => true" at the end
of the field specifier. The field name must currently begin with "encrypted_"

```ruby
# 'users' table has the following columns :first_name, :last_name, :address1, :address2
class User < ActiveRecord::Base
  include DataCleansing::Cleanse

  # Use a global cleaner
  cleanse :first_name, :last_name, :cleaner => :strip

  # Define a once off cleaner
  cleanse :address1, :address2, :cleaner => Proc.new {|string| string.strip!}

  # Automatically cleanse data before validation
  before_validation :cleanse_attributes!
end

# Define a global cleanser
DataCleansing.register_cleaner(:strip) {|string, params, object| string.strip!}

# Create a User instance
u = User.new(:first_name => '    joe   ', :last_name => "\n  black\n", :address1 => "2632 Brown St   \n")
puts "Before data cleansing #{u.attributes.inspect}"
u.validate
puts "After data cleansing #{u.attributes.inspect}"
u.save!
```

## Installation

### Add to an existing Rails project

Add the following line to Gemfile

```ruby
gem 'data_validation'
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

Meta
----

* Code: `git clone git://github.com/ClarityServices/data_cleansing.git`
* Home: <https://github.com/ClarityServices/data_cleansing>
* Issues: <http://github.com/ClarityServices/data_cleansing/issues>
* Gems: <http://rubygems.org/gems/data_cleansing>

This project uses [Semantic Versioning](http://semver.org/).

Authors
-------

Reid Morrison :: reidmo@gmail.com :: @reidmorrison

License
-------

Copyright 2013 Clarity Services, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
