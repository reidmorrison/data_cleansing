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
          attrs = cleaner_struct.attributes

          # Special case to include :all fields
          # Only works with ActiveRecord based models, not supported with regular Ruby models
          if attrs.include?(:all) && defined?(ActiveRecord) && respond_to?(:attributes)
            attrs = attributes.keys.collect{|i| i.to_sym}
            if except = params.delete(:except)
              attrs -= except
            end

            # Remove serialized_attributes if any, from the :all condition
            if self.class.respond_to?(:serialized_attributes)
              serialized_attrs = self.class.serialized_attributes.keys
              attrs -= serialized_attrs.collect{|i| i.to_sym} if serialized_attrs
            end

            # Replace any encrypted attributes with their non-encrypted versions if any
            if defined?(SymmetricEncryption) && self.class.respond_to?(:encrypted_attributes)
              self.class.encrypted_attributes.each_pair do |clear, encrypted|
                if attrs.include?(encrypted.to_sym)
                  attrs.delete(encrypted.to_sym)
                  attrs << clear.to_sym
                end
              end
            end
          end

          attrs.each do |attr|
            # Under ActiveModel for Rails and Mongoid need to retrieve raw value
            # before data type conversion
            value = if respond_to?(:read_attribute_before_type_cast)
              read_attribute_before_type_cast(attr.to_s)
            else
              send(attr.to_sym)
            end

            # No need to clean if attribute is nil
            unless value.nil?
              new_value = if cleaner.is_a?(Proc)
                cleaner.call(value, params)
              else
                if c = DataCleansing.cleaner(cleaner.to_sym)
                  c.call(value, params)
                else
                  raise "No cleaner defined for #{cleaner.to_sym.inspect}"
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
