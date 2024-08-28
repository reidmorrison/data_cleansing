require "data_cleansing/cleaners"
module DataCleansing
  # Mix-in to add cleaner
  module Cleanse
    DataCleansingCleaner = Struct.new(:cleaners, :attributes, :params)

    module ClassMethods
      # Define how to cleanse one or more attributes
      def cleanse(*args)
        last       = args.last
        attributes = args.dup
        params     = last.is_a?(Hash) && last.instance_of?(Hash) ? attributes.pop.dup : {}
        cleaners   = Array(params.delete(:cleaner))
        raise(ArgumentError, "Mandatory :cleaner parameter is missing: #{params.inspect}") unless cleaners

        cleaner = DataCleansingCleaner.new(cleaners, attributes, params)
        data_cleansing_cleaners << cleaner

        # Create shortcuts to cleaners for each attribute for use by .cleanse_attribute
        attributes.each do |attr|
          (data_cleansing_attribute_cleaners[attr] ||= Concurrent::Array.new) << cleaner
        end
        cleaner
      end

      # Add one or more methods on this object to be called after cleansing is complete
      # on an object
      # After cleansers are executed when #cleanse_attributes! is called, but after
      # all other defined cleansers have been executed.
      # They are _not_ called when .cleanse_attribute is called
      #
      # After cleaners should be used when based on the value of one attribute,
      # one or more of the other attributes need to be modified
      def after_cleanse(*methods)
        methods.each do |m|
          raise "Method #{m.inspect} must be a symbol" unless m.is_a?(Symbol)

          data_cleansing_after_cleaners << m unless data_cleansing_after_cleaners.include?(m)
        end
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
      def cleanse_attribute(attribute_name, value, object = nil)
        return if value.nil?

        # Collect parent cleaners first, starting with the top parent
        cleaners = []
        klass    = self
        while klass != Object
          if klass.respond_to?(:data_cleansing_attribute_cleaners)
            cleaners += klass.data_cleansing_attribute_cleaners[:all] || []
            cleaners += klass.data_cleansing_attribute_cleaners[attribute_name.to_sym] || []
          end
          klass = klass.superclass
        end
        # Support Integer values
        cleansed_value = value.is_a?(Integer) ? value : value.dup
        cleaners.reverse_each { |cleaner| cleansed_value = data_cleansing_clean(cleaner, cleansed_value, object) if cleaner }
        cleansed_value
      end

      # Array of cleaners to execute against this model and it's children
      def data_cleansing_cleaners
        @data_cleansing_cleaners ||= Concurrent::Array.new
      end

      # Array of cleaners to execute against this model and it's children
      def data_cleansing_after_cleaners
        @data_cleansing_after_cleaners ||= Concurrent::Array.new
      end

      # Hash of attributes to clean with their corresponding cleaner
      def data_cleansing_attribute_cleaners
        @data_cleansing_attribute_cleaners ||= Concurrent::Hash.new
      end

      private

      # Returns the supplied value cleansed using the supplied cleaner
      # Parameters
      #   binding
      #     If supplied the cleansing will be performed within the scope of
      #     that binding so that cleaners can read and write to attributes
      #     of that binding
      #
      # No logging of cleansing is performed by this method since the value
      # itself is not modified
      def data_cleansing_clean(cleaner_struct, value, binding = nil)
        return if cleaner_struct.nil? || value.nil?

        # Duplicate value in case cleaner uses methods such as gsub!
        new_value = value.is_a?(String) ? value.dup : value
        cleaner_struct.cleaners.each do |name|
          new_value = DataCleansing.clean(name, new_value, cleaner_struct.params, binding)
        end
        new_value
      end
    end

    module InstanceMethods
      # Cleanse the attributes using specified cleaners
      # and execute after cleaners once complete
      #
      # Returns fields changed whilst cleaning the attributes
      #
      # Note: At this time the changes returned does not include any fields
      #       modified in any of the after_cleaner methods
      def cleanse_attributes!(verbose = DataCleansing.logger.debug?)
        changes = {}
        DataCleansing.logger.benchmark_info("#{self.class.name}#cleanse_attributes!", payload: changes) do
          # Collect parent cleaners first, starting with the top parent
          cleaners       = [self.class.send(:data_cleansing_cleaners)]
          after_cleaners = [self.class.send(:data_cleansing_after_cleaners)]
          klass          = self.class.superclass
          while klass != Object
            cleaners << klass.send(:data_cleansing_cleaners) if klass.respond_to?(:data_cleansing_cleaners)
            after_cleaners << klass.send(:data_cleansing_after_cleaners) if klass.respond_to?(:data_cleansing_after_cleaners)
            klass = klass.superclass
          end
          # Capture all modified fields if log_level is :debug or :trace
          cleaners.reverse_each { |cleaner| changes.merge!(data_cleansing_execute_cleaners(cleaner, verbose)) }

          # Execute the after cleaners, starting with the parent after cleanse methods
          after_cleaners.reverse_each { |a| a.each { |method| send(method) } }
        end
        changes
      end

      private

      # Run each of the cleaners in the order they are listed in the array
      # Returns a hash of before and after values of what was cleansed
      # Parameters
      #   cleaners
      #     List of cleaners to run
      #
      #   verbose [true|false]
      #     Whether to include all the fields cleansed or just the fields that
      #     were cleansed to nil
      def data_cleansing_execute_cleaners(cleaners, verbose = false)
        return false if cleaners.nil?

        # Capture all changes to attributes if the log level is :info or greater
        changes = {}

        cleaners.each do |cleaner_struct|
          params = cleaner_struct.params
          attrs  = cleaner_struct.attributes

          # Special case to include :all fields
          # Only works with ActiveRecord based models, not supported with regular Ruby models
          if attrs.include?(:all) && defined?(ActiveRecord) && respond_to?(:attributes)
            attrs = attributes.keys.collect { |i| i.to_sym }
            attrs.delete(:id)
            if ActiveRecord.version < Gem::Version.new("7.0.0")
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

            # Explicitly remove specified attributes from cleansing
            if except = params[:except]
              attrs -= except
            end

          end

          attrs.each do |attr|
            # Under ActiveModel for Rails and Mongoid need to retrieve raw value
            # before data type conversion
            value =
              if respond_to?(:read_attribute_before_type_cast) && has_attribute?(attr.to_s)
                read_attribute_before_type_cast(attr.to_s)
              else
                send(attr.to_sym)
              end

            # No need to clean if attribute is nil
            next if value.nil?

            new_value = self.class.send(:data_cleansing_clean, cleaner_struct, value, self)

            next unless new_value != value

            # Update value only if it has changed
            send("#{attr.to_sym}=".to_sym, new_value)

            # Capture changed attributes
            next unless changes

            # Mask sensitive attributes when logging
            masked    = DataCleansing.masked_attributes.include?(attr.to_sym)
            new_value = :masked if masked && !new_value.nil?
            if previous = changes[attr.to_sym]
              previous[:after] = new_value
            elsif new_value.nil? || verbose
              changes[attr.to_sym] = {
                before: masked ? :masked : value,
                after:  new_value
              }
            end
          end
        end
        changes
      end
    end

    def self.included(base)
      base.class_eval do
        extend DataCleansing::Cleanse::ClassMethods
        include DataCleansing::Cleanse::InstanceMethods
      end
    end
  end
end
