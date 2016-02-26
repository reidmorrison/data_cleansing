module DataCleansing
  include SemanticLogger::Loggable

  # Global Data Cleansers
  @@global_cleaners     = Concurrent::Hash.new
  @@masked_attributes   = Concurrent::Array.new

  # Register a new cleaner
  # Replaces any existing cleaner with the same name
  def self.register_cleaner(name, cleaner = nil, &block)
    raise "Must supply a Proc with the cleaner" unless block || cleaner
    @@global_cleaners[name.to_sym] = cleaner || block
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

end
