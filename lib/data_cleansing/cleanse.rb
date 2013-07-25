module DataCleansing
  # Mix-in to add cleaner
  module Cleanse
    DataCleansingCleaner = Struct.new(:cleaners, :attributes, :params)

    module ClassMethods
      # Define how to cleanse one or more attributes
      def cleanse(*args)
        last = args.last
        attributes = args.dup
        params = (last.is_a?(Hash) && last.instance_of?(Hash)) ? attributes.pop.dup : {}
        cleaners = Array(params.delete(:cleaner))
        raise(ArgumentError, "Mandatory :cleaner parameter is missing: #{params.inspect}") unless cleaners
        cleaner = DataCleansingCleaner.new(cleaners, attributes, params)
        data_cleansing_cleaners << cleaner
        attributes.each do |attr|
          (data_cleansing_attribute_cleaners[attr] ||= ThreadSafe::Array.new) << cleaner
        end
        cleaner
      end

      # Returns the value cleansed using the cleaners defined for that attribute
      # in this model and any of it's parents
      #
      # Parameters
      #   attribute_name
      #     Name of the attribute within this Class to be cleansed
      #   value
      #     Value to be cleansed
      #   object
      #     If supplied the cleansing will be performed within the scope of
      #     that object so that cleaners can read and write to attributes
      #     of that object
      #
      # Warning: If any of the cleaners read or write to other object attributes
      #          then a valid object instance must be supplied
      def cleanse_attribute(attribute_name, value, object=nil)
        return if value.nil?

        # Collect parent cleaners first, starting with the top parent
        cleaners = []
        klass = self
        while klass != Object
          if klass.respond_to?(:data_cleansing_attribute_cleaners)
            cleaners += klass.data_cleansing_attribute_cleaners[:all] || []
            cleaners += klass.data_cleansing_attribute_cleaners[attribute_name.to_sym] || []
          end
          klass = klass.superclass
        end
        cleansed_value = value.dup
        cleaners.reverse_each {|cleaner| cleansed_value = data_cleansing_clean(cleaner, cleansed_value, object) if cleaner}
        cleansed_value
      end

      # Array of cleaners to execute against this model and it's children
      def data_cleansing_cleaners
        @data_cleansing_cleaners ||= ThreadSafe::Array.new
      end

      # Hash of attributes to clean with their corresponding cleaner
      def data_cleansing_attribute_cleaners
        @data_cleansing_attribute_cleaners ||= ThreadSafe::Hash.new
      end

      private

      # Returns the supplied value cleansed using the supplied cleaner
      # Parameters
      #   object
      #     If supplied the cleansing will be performed within the scope of
      #     that object so that cleaners can read and write to attributes
      #     of that object
      #
      # No logging of cleansing is performed by this method since the value
      # itself is not modified
      def data_cleansing_clean(cleaner_struct, value, object=nil)
        return if cleaner_struct.nil? || value.nil?
        # Duplicate value in case cleaner uses methods such as gsub!
        new_value = value.is_a?(String) ? value.dup : value
        cleaner_struct.cleaners.each do |cleaner|
          # Cleaner itself could be a custom Proc, otherwise do a global lookup for it
          proc = cleaner.is_a?(Proc) ? cleaner : DataCleansing.cleaner(cleaner.to_sym)
          raise "No cleaner defined for #{cleaner.inspect}" unless proc

          new_value = if object
            # Call the cleaner proc within the scope (binding) of the object
            proc.arity == 1 ? object.instance_exec(new_value, &proc) : object.instance_exec(new_value, cleaner_struct.params, &proc)
          else
            proc.arity == 1 ? proc.call(new_value) : proc.call(new_value, cleaner_struct.params)
          end
        end
        new_value
      end

    end

    module InstanceMethods
      # Cleanse the attributes using specified cleaners
      def cleanse_attributes!
        # Collect parent cleaners first, starting with the top parent
        cleaners = [self.class.send(:data_cleansing_cleaners)]
        klass = self.class.superclass
        while klass != Object
          cleaners << klass.send(:data_cleansing_cleaners) if klass.respond_to?(:data_cleansing_cleaners)
          klass = klass.superclass
        end
        cleaners.reverse_each {|cleaner| data_cleansing_execute_cleaners(cleaner)}
        true
      end

      private

      # Run each of the cleaners in the order they are listed in the array
      def data_cleansing_execute_cleaners(cleaners)
        return false if cleaners.nil?

        # Capture all changes to attributes if the log level is high enough
        changes = {} if DataCleansing.logger.send("#{DataCleansing.cleansing_log_level}?")

        #logger.send(self.class.data_cleansing_log_level, "Cleansed Attributes", changes) if changes
        DataCleansing.logger.send("benchmark_#{DataCleansing.cleansing_log_level}","Cleansed Attributes", :payload => changes) do
          cleaners.each do |cleaner_struct|
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
                new_value = self.class.send(:data_cleansing_clean,cleaner_struct, value, self)

                if new_value != value
                  # Update value only if it has changed
                  send("#{attr.to_sym}=".to_sym, new_value)

                  # Capture changed attributes
                  if changes
                    # Mask sensitive attributes when logging
                    masked = DataCleansing.masked_attributes.include?(attr.to_sym)
                    new_value = :masked if masked && !new_value.nil?
                    if previous = changes[attr.to_sym]
                      previous[:after] = new_value
                    else
                      changes[attr.to_sym] = {
                        :before => masked ? :masked : value,
                        :after  => new_value
                      }
                    end
                  end
                end
              end

            end
          end
        end
        nil
      end
    end

    def self.included(base)
      base.class_eval do
        extend  DataCleansing::Cleanse::ClassMethods
        include DataCleansing::Cleanse::InstanceMethods
      end
    end
  end

end
