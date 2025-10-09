# encoding: UTF-8
module MarkMapper
  module Plugins
    include ActiveSupport::DescendantsTracker

    def plugins
      @plugins ||= []
    end

    def plugin(mod)
      raise ArgumentError,  "Plugins must extend ActiveSupport::Concern" unless ActiveSupport::Concern === mod
      include mod
      descendants.each {|model| model.send(:include, mod) }
      plugins << mod
    end

    def included(base = nil)
      # Rails 8 compatibility - direct_descendants is no longer available
      # The descendants tracking is handled automatically by ActiveSupport::DescendantsTracker
      super
    end
  end
end
