# frozen_string_literal: true
require 'active_record'

module ActiveRecordCustomPreloader
  class AssociationsPreloader < ::ActiveRecord::Associations::Preloader
    private

    def preloaders_on(association, records, scope, polymorphic_parent = false)
      if association.is_a?(PreloadWithOptions)
        preloaders_for_one(association, records, scope, polymorphic_parent)
        return
      end

      klass = records.first.class
      if klass.respond_to?(:has_custom_loader?) && klass.has_custom_loader?(association)
        association = PreloadWithOptions.new(association)
        preloaders_for_one(association, records, scope, polymorphic_parent)
        return
      end

      super
    end

    def preloaders_for_one(association, records, scope, _polymorphic_parent)
      if records.size > 0 && association.is_a?(PreloadWithOptions)
        association.loader_for(records.first.class).preload(records)
        return
      end

      super
    end
  end
end
