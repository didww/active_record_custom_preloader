# frozen_string_literal: true
require 'active_record'

module ActiveRecordCustomPreloader
  class AssociationsPreloader < ::ActiveRecord::Associations::Preloader
    private

    def preloaders_for_one(association, records, scope)
      klass = records.first.class
      if klass.respond_to?(:has_custom_loader?) && klass.has_custom_loader?(association)
        klass.custom_loader_for(association).preload(records)
        return
      end
      super(association, records, scope)
    end
  end
end
