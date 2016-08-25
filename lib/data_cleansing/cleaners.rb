require 'cgi'
module Cleaners
  # Strip leading and trailing whitespace
  module Strip
    def self.call(string)
      return string unless string.is_a?(String)

      string.strip! || string
    end
  end
  DataCleansing.register_cleaner(:strip, Strip)

  # Convert to uppercase
  module Upcase
    def self.call(string)
      return string unless string.is_a?(String)

      string.upcase! || string
    end
  end
  DataCleansing.register_cleaner(:upcase, Upcase)

  # Convert to downcase
  module Downcase
    def self.call(string)
      return string unless string.is_a?(String)

      string.downcase! || string
    end
  end
  DataCleansing.register_cleaner(:downcase, Downcase)

  # Remove all non-word characters, including whitespace
  module RemoveNonWord
    NOT_WORDS = Regexp.compile(/\W/)

    def self.call(string)
      return string unless string.is_a?(String)

      string.gsub!(NOT_WORDS, '') || string
    end
  end
  DataCleansing.register_cleaner(:remove_non_word, RemoveNonWord)

  # Remove all not printable characters
  module RemoveNonPrintable
    NOT_PRINTABLE = Regexp.compile(/[^[:print:]]/)

    def self.call(string)
      return string unless string.is_a?(String)

      string.gsub!(NOT_PRINTABLE, '') || string
    end
  end
  DataCleansing.register_cleaner(:remove_non_printable, RemoveNonPrintable)

  # Unescape HTML Markup ( case-insensitive )
  module ReplaceHTMLMarkup
    HTML_MARKUP = Regexp.compile(/&(amp|quot|gt|lt|apos|nbsp);/in)

    def self.call(string)
      return string unless string.is_a?(String)

      string.gsub!(HTML_MARKUP) do |match|
        case match.downcase
        when '&amp;' then
          '&'
        when '&quot;' then
          '"'
        when '&gt;' then
          '>'
        when '&lt;' then
          '<'
        when '&apos;' then
          "'"
        when '&nbsp;' then
          ' '
        else
          "&#{match};"
        end
      end || string
    end
  end
  DataCleansing.register_cleaner(:replace_html_markup, ReplaceHTMLMarkup)

  module UnescapeURI
    def self.call(string)
      return string unless string.is_a?(String)

      CGI.unescape(string)
    end
  end
  DataCleansing.register_cleaner(:unescape_uri, UnescapeURI)

  module EscapeURI
    def self.call(string)
      return string unless string.is_a?(String)

      CGI.escape(string)
    end
  end
  DataCleansing.register_cleaner(:escape_uri, EscapeURI)

  # Compress multiple whitespace to a single space
  module CompressWhitespace
    WHITESPACE = Regexp.compile(/\s+/)

    def self.call(string)
      return string unless string.is_a?(String)

      string.gsub!(WHITESPACE, ' ') || string
    end
  end
  DataCleansing.register_cleaner(:compress_whitespace, CompressWhitespace)

  # Remove Non-Digit Chars
  # Returns nil if no digit characters present
  module DigitsOnly
    DIGITS = Regexp.compile(/\D/)

    def self.call(string)
      return string unless string.is_a?(String)

      string.gsub!(DIGITS, '')
      string.length > 0 ? string : nil
    end
  end
  DataCleansing.register_cleaner(:digits_only, DigitsOnly)

  # Returns [Integer] after removing all non-digit characters, except '.'
  # Returns nil if no digits are present in the string.
  module StringToInteger
    NUMERIC = Regexp.compile(/[^0-9\.]/)

    def self.call(string)
      return string unless string.is_a?(String)

      # Remove Non-Digit Chars, except for '.'
      string.gsub!(NUMERIC, '')
      string.length > 0 ? string.to_i : nil
    end
  end
  DataCleansing.register_cleaner(:string_to_integer, StringToInteger)

  # Returns [Integer] after removing all non-digit characters, except '.'
  # Returns nil if no digits are present in the string.
  module StringToFloat
    NUMERIC = Regexp.compile(/[^0-9\.]/)

    def self.call(string)
      return string unless string.is_a?(String)

      # Remove Non-Digit Chars, except for '.'
      string.gsub!(NUMERIC, '')
      string.length > 0 ? string.to_f : nil
    end
  end
  DataCleansing.register_cleaner(:string_to_float, StringToFloat)

  # Convert a Date to a Time at the end of day for that date (YYYY-MM-DD 23:59:59)
  # Ex: 2015-12-31 becomes 2015-12-31 23:59:59
  # If something other than a Date object is passed in, it just passes through.
  #
  # Note: Only works if ActiveSupport is also loaded since it defines Time#end_of_day.
  module EndOfDay
    def self.call(datetime)
      case datetime
      when String
        Time.parse(datetime).end_of_day
      when Date
        datetime.to_time.end_of_day
      when Time
        datetime.end_of_day
      else
        datetime
      end
    end
  end
  DataCleansing.register_cleaner(:end_of_day, EndOfDay)
end
