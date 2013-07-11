module DataCleansing
  # Mix-in to add cleaner
  module Cleanse
    CleanerStruct = Struct.new(:cleaner, :attributes, :params)

    module ClassMethods
      # Define how to cleanse one or more attributes
      def cleanse(*args)
        last = args.last
        params = (last.is_a?(Hash) && last.instance_of?(Hash)) ? args.pop.dup : {}
        cleaner = params.delete(:cleaner)
        raise(ArgumentError, "Mandatory :cleaner parameter is missing: #{params.inspect}") unless cleaner
        (@cleaners ||= ThreadSafe::Array.new) << CleanerStruct.new(cleaner, args, params)
      end

      def cleaners
        @cleaners
      end
    end

    module InstanceMethods
      # Cleanse the attributes using specified cleaners
      def cleanse_attributes!
        self.class.cleaners.each do |cleaner_struct|
          params  = cleaner_struct.params
          cleaner = cleaner_struct.cleaner
          cleaner_struct.attributes.each do |attr|
            value = send(attr.to_sym)
            # No need to clean if attribute is nil
            unless value.nil?
              new_value = if cleaner.is_a?(Proc)
                cleaner.call(value, params)
              else
                if c = DataCleansing.cleaner(cleaner)
                  c.call(value, params)
                else
                  raise "No cleaner defined for #{cleaner.to_sym}"
                end
              end
              # Update value if it has changed
              send("#{attr.to_sym}=".to_sym, new_value) if new_value != value
            end
          end
        end
      end
    end

    def self.included(base)
      base.class_eval do
        extend(DataCleansing::Cleanse::ClassMethods)
        include(DataCleansing::Cleanse::InstanceMethods)
      end
    end
  end

end
