require 'uri'
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

  # Remove HTML Markup
  module RemoveHTMLMarkup
    HTML_MARKUP = Regexp.compile(/&(amp|quot|gt|lt|apos|nbsp);/in)

    def self.call(string)
      return string unless string.is_a?(String)

      string.gsub!(HTML_MARKUP) do
        match = $1.dup
        case match.downcase
        when 'amp' then
          '&'
        when 'quot' then
          '"'
        when 'gt' then
          '>'
        when 'lt' then
          '<'
        when 'apos' then
          "'"
        when 'nbsp' then
          ' '
        else
          "&#{match};"
        end
      end || string
    end
  end
  DataCleansing.register_cleaner(:remove_html_markup, RemoveHTMLMarkup)

  module ReplaceURIChars
    def self.call(string)
      return string unless string.is_a?(String)

      URI.unescape(string)
    end
  end
  DataCleansing.register_cleaner(:replace_uri_chars, ReplaceURIChars)

  # Compress multiple whitespace to a single space
  module CompressWhitespace
    WHITESPACE = Regexp.compile(/\s+/)

    def self.call(string)
      return string unless string.is_a?(String)

      string.gsub!(WHITESPACE, ' ') || string
    end
  end
  DataCleansing.register_cleaner(:compress_whitespace, CompressWhitespace)

  # Compress double spaces to a single space
  module CompressDoubleSpace
    def self.call(string)
      return string unless string.is_a?(String)

      string.gsub!('  ', ' ') || string
    end
  end
  DataCleansing.register_cleaner(:compress_double_space, CompressDoubleSpace)

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

  # Convert a Date to a Time at the end of day for that date (YYYY-MM-DD 23:59:59)
  # Ex: 2015-12-31 becomes 2015-12-31 23:59:59
  # If something other than a Date object is passed in, it just passes through.
  module DateToTimeAtEndOfDay
    def self.call(date)
      return date unless date.kind_of?(Date)

      date.to_time.end_of_day
    end
  end
  DataCleansing.register_cleaner(:date_to_time_at_end_of_day, DateToTimeAtEndOfDay)
end
