# frozen_string_literal: true
require 'active_support/concern'

# Usage example:
#
#   class Employee < ApplicationRecord
#     # columns: id, name, department_id, position_id
#     add_custom_loader :_contract, class_name: 'EmployeeContractPreloader'
#   end
#
#   class Contract < ApplicationRecord
#     # columns: id, text, employee_department_id, position_id
#   end
#
#   class EmployeeContractPreloader < ActiveRecordCustomPreloader::Preloader
#     include ActiveRecordCustomPreloader::WithMultipleForeignKeysLoading
#     self.model_class_name = 'Contract'
#     self.association_foreign_keys_names = [:employee_department_id, :position_id]
#
#     def record_foreign_keys(record)
#       [record.department_id, record.position_id]
#     end
#   end
#
module ActiveRecordCustomPreloader
  module WithMultipleForeignKeysLoading
    extend ActiveSupport::Concern

    included do
      # should be true for has_many and false for has_one.
      # [optional] (default false)
      class_attribute :to_many, instance_writer: false
      self.to_many = false

      # model class of association records
      # [required]
      class_attribute :model_class_name, instance_writer: false

      # Names of foreign keys which link association record to parent record.
      # Should returns array of key names for association record for query.
      # [required]
      class_attribute :association_foreign_keys_names, instance_writer: false

      private :fetch_association
    end

    # association table is queried by return value of this method.
    # returns array of keys for parent record to match association record
    def record_foreign_keys(parent_record)
      association_foreign_keys(parent_record)
    end

    # association records are grouped by return value of this method.
    # it should match
    # returns array of keys for association record to match parent record
    def association_foreign_keys(assoc_record)
      association_foreign_keys_names.map { |name| assoc_record.public_send(name) }
    end

    # returns associations for provided parent_record.
    # array for has_many and model or nil for has_one.
    def associations_by_record(grouped_associations, parent_record)
      associations = grouped_associations[record_foreign_keys(parent_record)]
      to_many ? associations || [] : associations&.first
    end

    # default scope for association records.
    # you can override it for example to preload some values to association records.
    def associations_scope
      model_class_name.constantize.all
    end

    def fetch_association(parent_records)
      keys = parent_records.map(&method(:record_foreign_keys))
      condition_part = association_foreign_keys_names.map { |name| "#{name} = ?" }.join(' AND ')
      conditions = []
      keys.size.times { conditions.push(condition_part) }
      condition_sql = conditions.map { |condition| "(#{condition})" }.join(' OR ')
      condition_bindings = keys.flatten
      return associations_scope.none if condition_sql.blank? || condition_bindings.empty?
      associations = associations_scope.where(condition_sql, *condition_bindings).to_a
      associations.group_by(&method(:association_foreign_keys))
    end

    def preload(parent_records)
      grouped_associations = fetch_association(parent_records)
      parent_records.each do |parent_record|
        value = associations_by_record(grouped_associations, parent_record)
        parent_record._set_custom_preloaded_value(name, value)
      end
    end

  end
end
