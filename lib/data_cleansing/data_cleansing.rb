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
    attributes.each { |attr| @@masked_attributes << attr.to_sym }
  end

  # Returns the Global list of attributes to mask in any log output
  def self.masked_attributes
    @@masked_attributes.freeze
  end

  # Run the specified cleanser against the supplied value
  def self.clean(name, value, params = nil, binding = nil)
    # Cleaner itself could be a custom Proc, otherwise do a global lookup for it
    proc = name.is_a?(Proc) ? name : DataCleansing.cleaner(name.to_sym)
    raise(ArgumentError, "No cleaner defined for #{name.inspect}") unless proc

    if proc.is_a?(Proc)
      if binding
        # Call the cleaner proc within the scope (binding) of the binding
        proc.arity == 1 ? binding.instance_exec(value, &proc) : binding.instance_exec(value, params, &proc)
      else
        proc.arity == 1 ? proc.call(value) : proc.call(value, params)
      end
    else
      (proc.method(:call).arity == 1 ? proc.call(value) : proc.call(value, params))
    end
  end
end
