# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'data_cleansing'

# Define a global cleanser
DataCleansing.register_cleaner(:strip) {|string| string.strip}

# Non Cleansing base class
class RubyUserBase
  attr_accessor :version
end

class RubyUser < RubyUserBase
  include DataCleansing::Cleanse

  attr_accessor :first_name, :last_name, :address1, :address2

  # Use a global cleaner
  cleanse :first_name, :last_name, :cleaner => :strip

  # Define a once off cleaner
  cleanse :address1, :address2, :cleaner => Proc.new {|string| "<< #{string.strip} >>"}

  # Execute after cleanser
  after_cleanse :name_check

  # Called once cleaning has been completed
  def name_check
    # If first_name has a value, but last_name does not
    if last_name.nil? || (last_name.length == 0)
      self.last_name = first_name
      self.first_name = nil
    end
  end
end

class RubyUserChild < RubyUser
  attr_accessor :gender
  cleanse :gender, :cleaner => Proc.new {|gender| gender.to_s.strip.downcase}
end

# Another global cleaner, used by RubyUser2
DataCleansing.register_cleaner(:upcase) {|string| string.upcase}

class RubyUser2
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

class RubyTest < Test::Unit::TestCase
  context "Ruby Models" do

    should 'have globally registered cleaner' do
      assert DataCleansing.cleaner(:strip)
    end

    should 'Model.cleanse_attribute' do
      assert_equal 'male',                RubyUserChild.cleanse_attribute(:gender,     "\n   Male   \n"), RubyUserChild.send(:data_cleansing_attribute_cleaners)
      assert_equal 'joe',                 RubyUserChild.cleanse_attribute(:first_name, '    joe   '), RubyUserChild.send(:data_cleansing_attribute_cleaners)
      assert_equal 'black',               RubyUserChild.cleanse_attribute(:last_name,  "\n  black\n"), RubyUserChild.send(:data_cleansing_attribute_cleaners)
      assert_equal '<< 2632 Brown St >>', RubyUserChild.cleanse_attribute(:address1,   "2632 Brown St   \n"), RubyUserChild.send(:data_cleansing_attribute_cleaners)
    end

    context "with ruby user" do
      setup do
        @user = RubyUser.new
        @user.first_name = '    joe   '
        @user.last_name = "\n  black\n"
        @user.address1 = "2632 Brown St   \n"
      end

      should 'cleanse_attributes! using global cleaner' do
        @user.cleanse_attributes!
        assert_equal 'joe', @user.first_name
        assert_equal 'black', @user.last_name
      end

      should 'cleanse_attributes! using attribute specific custom cleaner' do
        @user.cleanse_attributes!
        assert_equal '<< 2632 Brown St >>', @user.address1
      end

      should 'cleanse_attributes! not cleanse nil attributes' do
        @user.first_name = nil
        @user.cleanse_attributes!
        assert_equal nil, @user.first_name
      end

      should 'cleanse_attributes! call after cleaner' do
        @user.first_name = 'Jack'
        @user.last_name = nil
        @user.cleanse_attributes!
        assert_equal nil, @user.first_name, @user.inspect
        assert_equal 'Jack', @user.last_name, @user.inspect
      end
    end

    context "with ruby user child" do
      setup do
        @user = RubyUserChild.new
        @user.first_name = '    joe   '
        @user.last_name  = "\n  black\n"
        @user.address1   = "2632 Brown St   \n"
        @user.gender     = "\n   Male   \n"
      end

      should 'cleanse_attributes! using global cleaner' do
        @user.cleanse_attributes!
        assert_equal 'joe', @user.first_name
        assert_equal 'black', @user.last_name
      end

      should 'cleanse_attributes! using attribute specific custom cleaner' do
        @user.cleanse_attributes!
        assert_equal '<< 2632 Brown St >>', @user.address1
      end

      should 'cleanse_attributes! not cleanse nil attributes' do
        @user.first_name = nil
        @user.cleanse_attributes!
        assert_equal nil, @user.first_name
      end

      should 'cleanse_attributes! clean child attributes' do
        @user.cleanse_attributes!
        assert_equal 'male', @user.gender
      end

    end

    context "with ruby user2" do
      setup do
        @user = RubyUser2.new
        @user.first_name = '    joe   '
        @user.last_name  = "\n  black\n"
        @user.address1   = "2632 Brown St   \n"
        @user.title      = "   \nmr   \n"
        @user.gender     = " Unknown  "
      end

      should 'cleanse_attributes!' do
        @user.cleanse_attributes!
        assert_equal 'joe', @user.first_name
        assert_equal 'black', @user.last_name
        assert_equal '2632 Brown St', @user.address1
      end

      should 'cleanse_attributes! with multiple cleaners' do
        @user.cleanse_attributes!
        assert_equal 'MR.', @user.title
      end

      should 'cleanse_attributes! referencing other attributes' do
        @user.cleanse_attributes!
        assert_equal 'Male', @user.gender
      end
    end

  end
end