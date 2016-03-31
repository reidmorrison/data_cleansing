require_relative 'test_helper'
require 'active_support/core_ext/time/calculations'

class CleanersTest < Minitest::Test
  class User
    include DataCleansing::Cleanse

    attr_accessor :first_name, :last_name, :address1, :address2,
      :make_this_upper, :clean_non_word, :clean_non_printable,
      :clean_html, :clean_from_uri, :clean_to_uri, :clean_whitespace,
      :clean_digits_only, :clean_to_integer, :clean_to_float, :clean_end_of_day,
      :clean_order

    cleanse :first_name, :last_name, :address1, :address2, cleaner: :strip
    cleanse :make_this_upper, cleaner: :upcase
    cleanse :clean_non_word, cleaner: :remove_non_word
    cleanse :clean_non_printable, cleaner: :remove_non_printable
    cleanse :clean_html, cleaner: :replace_html_markup
    cleanse :clean_from_uri, cleaner: :unescape_uri
    cleanse :clean_to_uri, cleaner: :escape_uri
    cleanse :clean_whitespace, cleaner: :compress_whitespace
    cleanse :clean_digits_only, cleaner: :digits_only
    cleanse :clean_to_integer, cleaner: :string_to_integer
    cleanse :clean_to_float, cleaner: :string_to_float
    cleanse :clean_end_of_day, cleaner: :end_of_day

    # Call cleaners in the order they are defined
    cleanse :clean_order, cleaner: [:upcase, :strip]
    cleanse :clean_order, cleaner: -> val { val == 'BLAH' ? ' yes ' : ' no ' }
  end

  describe 'Cleaners' do
    it '#strip' do
      user            = User.new
      user.first_name = '     jack   black     '
      user.last_name  = "  \n  \t   joe"
      user.address1   = "joe \n\n   \n  \t\t    "
      user.address2   = "joe \n\n bloggs  \n  \t\t    "
      user.cleanse_attributes!
      assert_equal 'jack   black', user.first_name
      assert_equal 'joe', user.last_name
      assert_equal 'joe', user.address1
      assert_equal "joe \n\n bloggs", user.address2
    end

    it '#upcase' do
      user                 = User.new
      user.make_this_upper = '     jacK   blAck     '
      user.cleanse_attributes!
      assert_equal '     JACK   BLACK     ', user.make_this_upper
    end

    it '#remove_non_word' do
      user                = User.new
      user.clean_non_word = "  !@#$%^&*()+=-~`\t\n   jacK   blAck   <>.,/\"':;{][]\|?/\\  "
      user.cleanse_attributes!
      assert_equal 'jacKblAck', user.clean_non_word
    end

    it '#remove_non_printable' do
      user                     = User.new
      user.clean_non_printable = "  !@#$%^&*()+=-~`\t\n   jacK   blAck   <>.,/\"':;{][]\|?/\\  "
      user.cleanse_attributes!
      assert_equal "  !@#$%^&*()+=-~`   jacK   blAck   <>.,/\"':;{][]\|?/\\  ", user.clean_non_printable
    end

    describe '#clean_html' do
      it 'cleans &quot;' do
        user            = User.new
        user.clean_html = 'O&quot;Leary'
        user.cleanse_attributes!
        assert_equal 'O"Leary', user.clean_html
      end

      it 'cleans &amp;' do
        user            = User.new
        user.clean_html = 'Jim &amp; Candi'
        user.cleanse_attributes!
        assert_equal 'Jim & Candi', user.clean_html
      end

      it 'cleans &gt;' do
        user            = User.new
        user.clean_html = '2 &gt; 1'
        user.cleanse_attributes!
        assert_equal '2 > 1', user.clean_html
      end

      it 'cleans &lt;' do
        user            = User.new
        user.clean_html = '1 &lt; 2'
        user.cleanse_attributes!
        assert_equal '1 < 2', user.clean_html
      end

      it 'cleans &apos;' do
        user            = User.new
        user.clean_html = '1&apos;2'
        user.cleanse_attributes!
        assert_equal "1'2", user.clean_html
      end

      it 'cleans &nbsp;' do
        user            = User.new
        user.clean_html = '1&nbsp;2'
        user.cleanse_attributes!
        assert_equal "1 2", user.clean_html
      end

      it 'cleans &AMP;' do
        user            = User.new
        user.clean_html = 'Mutt &AMP; Jeff Inc.'
        user.cleanse_attributes!
        assert_equal 'Mutt & Jeff Inc.', user.clean_html
      end

      it 'does not clean &;' do
        user            = User.new
        user.clean_html = 'Mutt &; Jeff Inc.'
        user.cleanse_attributes!
        assert_equal 'Mutt &; Jeff Inc.', user.clean_html
      end

      it 'does not clean &blah;' do
        user            = User.new
        user.clean_html = '1&blah;2'
        user.cleanse_attributes!
        assert_equal '1&blah;2', user.clean_html
      end
    end

    describe '#unescape_uri' do
      it 'converts %20' do
        user                = User.new
        user.clean_from_uri = 'Jim%20%20Bob%20'
        user.cleanse_attributes!
        assert_equal 'Jim  Bob ', user.clean_from_uri
      end
      it 'converts %20 only' do
        user                = User.new
        user.clean_from_uri = '%20'
        user.cleanse_attributes!
        assert_equal ' ', user.clean_from_uri
      end
    end

    describe '#escape_uri' do
      it 'converts spaces' do
        user              = User.new
        user.clean_to_uri = 'Jim  Bob '
        user.cleanse_attributes!
        assert_equal 'Jim++Bob+', user.clean_to_uri
      end
      it 'converts space only' do
        user              = User.new
        user.clean_to_uri = ' '
        user.cleanse_attributes!
        assert_equal '+', user.clean_to_uri
      end
    end

    describe '#compress_whitespace' do
      it 'compresses multiple spaces' do
        user                  = User.new
        user.clean_whitespace = '    J im  B ob       '
        user.cleanse_attributes!
        assert_equal ' J im B ob ', user.clean_whitespace
      end

      it 'does not compress single spaces' do
        user                  = User.new
        user.clean_whitespace = ' Jack Black'
        user.cleanse_attributes!
        assert_equal ' Jack Black', user.clean_whitespace
      end

      it 'compresses newlines and tabs' do
        user                  = User.new
        user.clean_whitespace = "  \n\n  J im  B ob  \t\n\t     "
        user.cleanse_attributes!
        assert_equal ' J im B ob ', user.clean_whitespace
      end
    end

    it '#digits_only' do
      user                   = User.new
      user.clean_digits_only = " 1 !@#$%^&*3()+=-~`\t\n   jacK6   blAck   <>.,/\"':;8{][]9\|?/\\  "
      user.cleanse_attributes!
      assert_equal '13689', user.clean_digits_only
    end

    it '#string_to_integer' do
      user                  = User.new
      user.clean_to_integer = " 1 !@#$%^&*3()+=-~`\t\n   jacK6   blAck   <>.,/\"':;8{][]9\|?/\\  "
      user.cleanse_attributes!
      assert_equal 136, user.clean_to_integer
    end

    it '#string_to_float' do
      user                = User.new
      user.clean_to_float = " 1 !@#$%^&*3()+=-~`\t\n   jacK6   blAck   <>.,/\"':;8{][]9\|?/\\  "
      user.cleanse_attributes!
      assert_equal 136.89, user.clean_to_float
    end

    it '#date_to_time_at_end_of_day' do
      user                  = User.new
      user.clean_end_of_day = Time.parse('2016-03-03 14:33:44 +0000')
      user.cleanse_attributes!
      assert_equal Time.parse('2016-03-03 23:59:59 +0000').to_i, user.clean_end_of_day.to_i
    end

    it 'cleans in the order defined' do
      user             = User.new
      user.clean_order = '  blah '
      user.cleanse_attributes!
      assert_equal ' yes ', user.clean_order
    end

  end
end
