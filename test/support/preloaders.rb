class ApplicationPreloader < ActiveRecordCustomPreloader::Preloader
end

class SimpleUserPreloader < ApplicationPreloader
  def preload(records)
    ids = records.map(&:id)
    records.each do |record|
      value = OpenStruct.new(ids: ids, record_id: record.id, args: args)
      record._set_custom_preloaded_value(name, value)
    end
  end
end
