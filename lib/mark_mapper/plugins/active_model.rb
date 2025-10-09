# encoding: UTF-8
module MarkMapper
  module Plugins
    module ActiveModel
      extend ActiveSupport::Concern

      include ::ActiveModel::Conversion
      include ::ActiveModel::Serialization
      include ::ActiveModel::Serializers::JSON
      
      # Rails 8+ compatibility - XML serialization moved to separate gem
      if defined?(::ActiveModel::Serializers::Xml)
        include ::ActiveModel::Serializers::Xml
      end

      included do
        extend ::ActiveModel::Naming
        extend ::ActiveModel::Translation
      end
    end
  end
end