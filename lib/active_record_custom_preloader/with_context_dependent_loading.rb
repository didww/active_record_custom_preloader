# frozen_string_literal: true
require 'active_support/concern'

# Usage example:
#
#   class User < ApplicationRecord
#     # columns: id, name, pricelist_id
#   end
#
#   class Pricelist < ApplicationRecord
#     # columns: id, name
#   end
#
#   class Discount < ApplicationRecord
#     # columns id, user_pricelist_id, product_id, percentage
#   end
#
#   class Product < ApplicationRecord
#     # columns: id, name, price
#     add_loader :_discount, class_name: 'ProductDiscountPreloader'
#   end
#
#   class ProductDiscountPreloader < ActiveRecordCustomPreloader::Preloader
#     include ActiveRecordCustomPreloader::WithContextDependentLoading
#     self.to_many = true
#     self.association_group_key = :user_pricelist_id
#     self.record_group_key = :pricelist_id
#
#     def scoped_collection(records)
#       product_ids = records.map(&:id)
#       pricelist_id = args.fetch(:pricelist_id)
#       Discount.where(user_pricelist_id: pricelist_id, product_id: product_ids)
#     end
#   end
#
#   user = User.first
#   products = Product.limit(10).custom_preload(:_discount, pricelist_id: user.pricelist_id)
#   products.first._discount # will return array with zero or more Discount records
#
module ActiveRecordCustomPreloader
  module WithContextDependentLoading
    extend ActiveSupport::Concern

    included do
      # should be true for has_many and false for has_one.
      # [optional] (default false)
      class_attribute :to_many, instance_writer: false
      self.to_many = false

      # by this method association records will be grouped
      # [required]
      class_attribute :association_group_key, instance_writer: false

      # by this method grouped association records will be matched with parent record
      # [required]
      class_attribute :record_group_key, instance_writer: false
    end

    # should return associations scope.
    # must be overridden.
    def scoped_collection(_parent_records)
      raise NotImplementedError.new 'override #scoped_collection in a subclass'
    end

    # returns associations for provided parent_record.
    # array for has_many and model or nil for has_one.
    def associations_by_record(grouped_associations, parent_record)
      key = parent_record.public_send(record_group_key)
      associations = grouped_associations[key]
      to_many ? associations || [] : associations&.first
    end

    def fetch_association(parent_records)
      scope = scoped_collection(parent_records)
      scope.to_a.group_by(&association_group_key)
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
