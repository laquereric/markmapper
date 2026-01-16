# encoding: UTF-8
module MarkMapper
  module Plugins
    module Dirty
      extend ActiveSupport::Concern

      include ::ActiveModel::Dirty

      def initialize(*)
        @_initializing = true
        @_changed_attributes = {}
        @previously_changed = {}
        doc = super
        @_initializing = false
        # Clear any changes tracked during initialization
        @_changed_attributes.clear
        doc
      end

      def initialize_from_database(*)
        @_initializing = true
        @_changed_attributes = {}
        @previously_changed = {}
        doc = super
        @_initializing = false
        @_changed_attributes.clear
        doc
      end

      def save(*)
        clear_changes { super }
      end

      def reload(*)
        doc = super
        doc.tap { clear_changes }
      end

      def clear_changes
        previous = @_changed_attributes.dup
        (block_given? ? yield : true).tap do |result|
          unless result == false #failed validation; nil is OK.
            @previously_changed = previous
            @_changed_attributes.clear
          end
        end
      end

      # Override ActiveModel::Dirty methods to use our internal tracking
      def changed?
        @_changed_attributes.any?
      end

      def changed
        @_changed_attributes.keys
      end

      def changes
        @_changed_attributes.transform_values { |old_val| [old_val, read_key(@_changed_attributes.key(old_val))] }
          .transform_keys(&:to_s)
          .select { |k, v| v[0] != v[1] }
      end

      def changed_attributes
        @_changed_attributes.transform_keys(&:to_s)
      end

      def previous_changes
        @previously_changed || {}
      end

      protected

      # We don't call super here to avoid invoking #attributes, which builds a whole new hash per call.
      def attribute_method?(attr_name)
        keys.key?(attr_name) || !embedded_associations.detect {|a| a.name == attr_name }.nil?
      end

      private

      def write_key(key, value)
        key = unalias_key(key)
        if !keys.key?(key)
          super
        elsif @_initializing
          # Skip dirty tracking during initialization
          super
        else
          old_value = read_key(key)
          super.tap do
            new_value = read_key(key)
            if old_value != new_value
              @_changed_attributes[key] ||= old_value
            elsif @_changed_attributes[key] == new_value
              # Value changed back to original
              @_changed_attributes.delete(key)
            end
          end
        end
      end

      # Generate attribute-specific dirty methods
      def respond_to_missing?(method_name, include_private = false)
        attr_name = method_name.to_s.sub(/(_changed\?|_was|_change|_will_change!|_previously_changed\?|_previous_change)$/, '')
        if method_name.to_s =~ /(_changed\?|_was|_change|_will_change!|_previously_changed\?|_previous_change)$/ && keys.key?(attr_name)
          true
        else
          super
        end
      end

      def method_missing(method_name, *args, &block)
        attr_name = method_name.to_s.sub(/(_changed\?|_was|_change|_will_change!|_previously_changed\?|_previous_change)$/, '')
        suffix = method_name.to_s[attr_name.length..]

        if keys.key?(attr_name)
          key_sym = attr_name.to_sym
          case suffix
          when '_changed?'
            @_changed_attributes.key?(key_sym) || @_changed_attributes.key?(attr_name)
          when '_was'
            if @_changed_attributes.key?(key_sym)
              @_changed_attributes[key_sym]
            elsif @_changed_attributes.key?(attr_name)
              @_changed_attributes[attr_name]
            else
              read_key(attr_name)
            end
          when '_change'
            if @_changed_attributes.key?(key_sym)
              [@_changed_attributes[key_sym], read_key(attr_name)]
            elsif @_changed_attributes.key?(attr_name)
              [@_changed_attributes[attr_name], read_key(attr_name)]
            else
              nil
            end
          when '_will_change!'
            @_changed_attributes[key_sym] ||= read_key(attr_name)
          when '_previously_changed?'
            previous_changes.key?(attr_name) || previous_changes.key?(key_sym.to_s)
          when '_previous_change'
            previous_changes[attr_name] || previous_changes[key_sym.to_s]
          else
            super
          end
        else
          super
        end
      end
    end
  end
end
