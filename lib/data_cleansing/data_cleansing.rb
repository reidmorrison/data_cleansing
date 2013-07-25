module DataCleansing
  include SemanticLogger::Loggable

  # Global Data Cleansers
  @@global_cleaners     = ThreadSafe::Hash.new
  @@masked_attributes   = ThreadSafe::Array.new
  @@cleansing_log_level = :info

  # Register a new cleaner
  # Replaces any existing cleaner with the same name
  def self.register_cleaner(cleaner, &block)
    raise "Must supply a Proc with the cleaner" unless block
    @@global_cleaners[cleaner.to_sym] = block
  end

  # Returns the cleaner matching the supplied cleaner name
  def self.cleaner(cleaner_name)
    @@global_cleaners[cleaner_name.to_sym]
  end

  # Register Attributes to be masked out in any log output
  def self.register_masked_attributes(*attributes)
    attributes.each {|attr| @@masked_attributes << attr.to_sym }
  end

  # Returns the Global list of attributes to mask in any log output
  def self.masked_attributes
    @@masked_attributes.freeze
  end

  # Set the log_level at which to log cleansing activities at
  def self.cleansing_log_level
    @@cleansing_log_level
  end

  # Set the log_level at which to log cleansing activities at
  def self.cleansing_log_level=(log_level)
    @@cleansing_log_level = log_level
  end

end
