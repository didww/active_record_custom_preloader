class ApplicationPreloader < ActiveRecordCustomPreloader::Preloader
end

class SimpleUserPreloader < ApplicationPreloader
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
