# Allow examples to be run in-place without requiring a gem install
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'data_cleansing'

# Define a global cleanser
DataCleansing.register_cleaner(:strip) {|string, params, object| string.to_s.strip!}

class User
  include DataCleansing::Cleanse

  attr_accessor :first_name, :last_name, :address1, :address2

  # Use a global cleaner
  cleanse :first_name, :last_name, :cleaner => :strip

  # Define a once off cleaner
  cleanse :address1, :address2, :cleaner => Proc.new {|string| "<< #{string.strip!} >>"}
end

class RubyTest < Test::Unit::TestCase
  context "Ruby Models" do

    should 'have globally registered cleaner' do
      assert DataCleansing.cleaner(:strip)
    end

    context "with ruby user" do
      setup do
        @user = User.new
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
    end

  end
end