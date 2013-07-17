module DataCleansing
  # Mix-in to add cleaner
  module Cleanse
    CleanerStruct = Struct.new(:cleaners, :attributes, :params)

    module ClassMethods
      # Define how to cleanse one or more attributes
      def cleanse(*args)
        last = args.last
        params = (last.is_a?(Hash) && last.instance_of?(Hash)) ? args.pop.dup : {}
        cleaners = Array(params.delete(:cleaner))
        raise(ArgumentError, "Mandatory :cleaner parameter is missing: #{params.inspect}") unless cleaners
        (@cleaners ||= ThreadSafe::Array.new) << CleanerStruct.new(cleaners, args, params)
        nil
      end

      def cleaners
        @cleaners
      end
    end

    module InstanceMethods
      # Cleanse the attributes using specified cleaners
      def cleanse_attributes!
        self.class.cleaners.each do |cleaner_struct|
          params = cleaner_struct.params
          attrs  = cleaner_struct.attributes

          # Special case to include :all fields
          # Only works with ActiveRecord based models, not supported with regular Ruby models
          if attrs.include?(:all) && defined?(ActiveRecord) && respond_to?(:attributes)
            attrs = attributes.keys.collect{|i| i.to_sym}
            attrs.delete(:id)

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

            # Explicitly remove specified attributes from cleansing
            if except = params[:except]
              attrs -= except
            end

          end

          attrs.each do |attr|
            # Under ActiveModel for Rails and Mongoid need to retrieve raw value
            # before data type conversion
            value = if respond_to?(:read_attribute_before_type_cast) && has_attribute?(attr.to_s)
              read_attribute_before_type_cast(attr.to_s)
            else
              send(attr.to_sym)
            end

            # No need to clean if attribute is nil
            unless value.nil?
              # Allow multiple cleaners to be defined and only set the new value
              # once all cleaners have run
              new_value = value
              cleaner_struct.cleaners.each do |cleaner|
                # Cleaner itself could be a custom Proc, otherwise do a global lookup for it
                proc = cleaner.is_a?(Proc) ? cleaner : DataCleansing.cleaner(cleaner.to_sym)
                raise "No cleaner defined for #{cleaner.inspect}" unless proc

                # Call the cleaner proc within the scope (binding) of this object
                new_value = instance_exec(new_value, params, &proc)
              end
              # Update value if it has changed
              send("#{attr.to_sym}=".to_sym, new_value) if new_value != value
            end

          end
        end
        nil
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
