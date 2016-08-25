require_relative 'test_helper'
require 'active_record'

ActiveRecord::Base.logger = SemanticLogger[ActiveRecord::Base]
ActiveRecord::Base.configurations = {
  'test' => {
    'adapter'  => 'sqlite3',
    'database' => 'test/test_db.sqlite3',
    'pool'     => 5,
    'timeout'  => 5000
  }
}
ActiveRecord::Base.establish_connection(:test)

ActiveRecord::Schema.define :version => 0 do
  create_table :users, :force => true do |t|
    t.string  :first_name
    t.string  :last_name
    t.string  :address1
    t.string  :address2
    t.string  :ssn
    t.integer :zip_code
    t.text    :text
  end
end

# Log data cleansing result
# Set to :warn or higher to disable
DataCleansing.logger.level = :debug

# Set the Global list of fields to be masked
DataCleansing.register_masked_attributes :ssn, :bank_account_number

class User < ActiveRecord::Base
  include DataCleansing::Cleanse

  # Also cleanse non-database backed fields
  attr_accessor :instance_var

  # Use a global cleaner
  cleanse :first_name, :last_name, :cleaner => :strip

  # Define a once off cleaner
  cleanse :address1, :address2, :instance_var, :cleaner => Proc.new {|string| "<< #{string.strip} >>"}

  # Custom Zip Code cleaner
  cleanse :zip_code, :cleaner => :string_to_integer

  # Automatically cleanse data before validation
  before_validation :cleanse_attributes!
end

class User2 < ActiveRecord::Base
  include DataCleansing::Cleanse
  # Use the same table as User above
  self.table_name = 'users'

  serialize :text

  # Test :all cleaner. Only works with ActiveRecord Models
  # Must explicitly excelude :text since it is serialized
  cleanse :all, :cleaner => [:strip, Proc.new{|s| "@#{s}@"}], :except => [:address1, :zip_code, :text]

  # Clean :first_name multiple times
  cleanse :first_name, :cleaner => Proc.new {|string| "<< #{string} >>"}

  # Clean :first_name multiple times
  cleanse :first_name, :cleaner => Proc.new {|string| "$#{string}$"}

  # Custom Zip Code cleaner
  cleanse :zip_code, :cleaner => :string_to_integer

  # Automatically cleanse data before validation
  before_validation :cleanse_attributes!
end

class ActiveRecordTest < Minitest::Test
  describe 'ActiveRecord Models' do

    it 'have globally registered cleaner' do
      assert DataCleansing.cleaner(:strip)
    end

    it 'Model.cleanse_attribute' do
      assert_equal 'joe',                 User.cleanse_attribute(:first_name,   '    joe   ')
      assert_equal 'black',               User.cleanse_attribute(:last_name,    "\n  black\n")
      assert_equal '<< 2632 Brown St >>', User.cleanse_attribute(:address1,     "2632 Brown St   \n")
      assert_equal '<< instance >>',      User.cleanse_attribute(:instance_var, "\n    instance\n\t      ")
      assert_equal 12345,                 User.cleanse_attribute(:zip_code,     "\n\tblah 12345badtext\n")
    end

    describe "with user" do
      before do
        @user = User.new(
          :first_name   => '    joe   ',
          :last_name    => "\n  black\n",
          :address1     => "2632 Brown St   \n",
          :zip_code     => "\n\tblah 12345badtext\n",
          :instance_var => "\n    instance\n\t      "
        )
      end

      it 'only have 3 cleaners' do
        assert_equal 3, User.send(:data_cleansing_cleaners).size, User.send(:data_cleansing_cleaners)
      end

      it 'cleanse_attributes! using global cleaner' do
        assert_equal true, @user.valid?
        assert_equal 'joe', @user.first_name
        assert_equal 'black', @user.last_name
      end

      it 'cleanse_attributes! using attribute specific custom cleaner' do
        assert_equal true, @user.valid?
        assert_equal '<< 2632 Brown St >>', @user.address1
        assert_equal '<< instance >>', @user.instance_var
      end

      it 'cleanse_attributes! using global cleaner using rails extensions' do
        @user.cleanse_attributes!
        assert_equal 12345, @user.zip_code
      end
    end

    describe 'with user2' do
      before do
        @user = User2.new(
          :first_name => '    joe   ',
          :last_name  => "\n  black\n",
          :ssn        => "\n    123456789   \n  ",
          :address1   => "2632 Brown St   \n",
          :zip_code   => "\n\t  blah\n",
          :text       => ["\n    123456789   \n  ", ' second ']
        )
      end

      it 'have 4 cleaners defined' do
        assert_equal 4, User2.send(:data_cleansing_cleaners).size, User2.send(:data_cleansing_cleaners)
      end

      it 'have 3 attributes cleaners defined' do
        # :all, :first_name, :zip_code
        assert_equal 3, User2.send(:data_cleansing_attribute_cleaners).size, User2.send(:data_cleansing_attribute_cleaners)
      end

      it 'cleanse_attributes! clean all attributes' do
        assert_equal true, @user.valid?
        assert_equal '$<< @joe@ >>$', @user.first_name, User2.send(:data_cleansing_cleaners)
        assert_equal '@black@', @user.last_name
        assert_equal "2632 Brown St   \n", @user.address1
        assert_equal "@123456789@", @user.ssn
        assert_equal nil, @user.zip_code, User2.send(:data_cleansing_cleaners)
        assert_equal ["\n    123456789   \n  ", ' second '], @user.text
      end

    end

  end
end
