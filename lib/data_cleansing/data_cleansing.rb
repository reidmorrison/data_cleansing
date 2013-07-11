module DataCleansing

  # Global Data Cleansers
  @@global_cleaners = ThreadSafe::Hash.new

  # Register a new cleaner
  def self.register_cleaner(cleaner, &block)
    if block
      raise "Cleaner: #{cleaner.inspect} has already been registered. Call unregister_cleaner to remove it first" if @@global_cleaners[cleaner.to_sym]
      @@global_cleaners[cleaner.to_sym] = block
    else
      # TODO Expose class methods as cleaners
      #
      # cleaners[cleaner.to_sym] = block
      # raise ArgumentError, "Must supply either a Proc, or a cleaner klass"
    end
  end

  # Returns the cleaner matching the supplied cleaner name
  def self.cleaner(cleaner_name)
    @@global_cleaners[cleaner_name.to_sym]
  end
end
