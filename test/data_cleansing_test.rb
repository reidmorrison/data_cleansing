require_relative 'test_helper'

class DataCleansingTest < Minitest::Test
  describe '#clean' do
    it 'can call any cleaner directly' do
      assert_equal 'jack   black', DataCleansing.clean(:strip, '     jack   black     ')
    end
  end
end
