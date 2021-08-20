# frozen_string_literal: true
require 'active_support/concern'

# Usage example:
#
#   class Employee < ApplicationRecord
#     # columns: id, name, department_ids
#     add_custom_loader :_departments, class_name: 'EmployeeDepartmentPreloader'
#   end
#
#   class Department < ApplicationRecord
#     # columns: id, name
#   end
#
#   class EmployeeDepartmentPreloader < ActiveRecordCustomPreloader::Preloader
#     include ActiveRecordCustomPreloader::WithArrayForeignKeysLoading
#     self.model_class_name = 'Department'
#     self.association_foreign_keys_names = :department_ids
#     self.keep_sorting = true
#   end
#
module ActiveRecordCustomPreloader
  module WithArrayForeignKeysLoading
    extend ActiveSupport::Concern

    included do
      # set to true if you want associated records to be sorted in same way as ids.
      # [optional] (default false)
      class_attribute :keep_sorting, instance_writer: false
      self.keep_sorting = false

      # model class of association records
      # [required]
      class_attribute :model_class_name, instance_writer: false

      # Name of foreign keys array which link association record to parent record.
      # Should returns symbol name of a column or parent record instance method.
      # [required]
      class_attribute :association_foreign_keys_name, instance_writer: false

      private :fetch_association, :associations_by_parent_record
    end

    # returns associations for provided parent_record.
    # array for has_many and model or nil for has_one.
    def associations_by_parent_record(parent_record, association_records)
      ids = parent_record.public_send(association_foreign_keys_name)
      return [] if ids.nil? || ids.empty?
      result = association_records.select { |r| ids.include?(r.id) }
      result.sort_by! { |r| ids.index r.id } if keep_sorting
      result
    end

    def fetch_association(parent_records)
      ids = parent_records.map(&association_foreign_keys_name).flatten.uniq.compact
      return [] if ids.empty?

      associations_scope.where(id: ids).to_a
    end

    # default scope for association records.
    # you can override it for example to preload some values to association records.
    def associations_scope
      model_class_name.constantize.all
    end

    def preload(parent_records)
      association_records = fetch_association(parent_records)
      parent_records.each do |parent_record|
        value = associations_by_parent_record(parent_record, association_records)
        parent_record._set_custom_preloaded_value(name, value)
      end
    end

  end
end
