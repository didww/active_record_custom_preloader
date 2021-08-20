class ApplicationPreloader < ActiveRecordCustomPreloader::Preloader
end

class SimplePreloader < ApplicationPreloader
  class_attribute :_called, instance_accessor: false, default: 0

  def preload(records)
    self.class._called += 1
    ids = records.map(&:id)
    records.each do |record|
      value = OpenStruct.new(ids: ids, record_id: record.id, args: args)
      record._set_custom_preloaded_value(name, value)
    end
  end
end

class UserDepartmentsPreloader < ApplicationPreloader
  include ActiveRecordCustomPreloader::WithArrayForeignKeysLoading
  self.model_class_name = 'Department'
  self.association_foreign_keys_name = :department_ids
  self.keep_sorting = true

  class_attribute :_called, instance_accessor: false, default: 0

  def preload(records)
    self.class._called += 1
    super
  end
end

class UserPricesPreloader < ApplicationPreloader
  include ActiveRecordCustomPreloader::WithMultipleForeignKeysLoading
  self.model_class_name = 'Price'
  self.association_foreign_keys_names = [:pricelist_id, :price_bundle_id]
  self.to_many = true

  class_attribute :_called, instance_accessor: false, default: 0

  def preload(records)
    self.class._called += 1
    super
  end
end

class UserDiscountPreloader < ApplicationPreloader
  include ActiveRecordCustomPreloader::WithMultipleForeignKeysLoading
  self.model_class_name = 'Discount'
  self.association_foreign_keys_names = [:pricelist_id, :price_bundle_id]

  class_attribute :_called, instance_accessor: false, default: 0

  def preload(records)
    self.class._called += 1
    super
  end
end
