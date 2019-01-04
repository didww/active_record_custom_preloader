# frozen_string_literal: true

module ActiveRecordCustomPreloader
  class Preloader
    attr_reader :klass, :name, :args

    def initialize(klass, name, args)
      @klass = klass
      @name = name
      @args = args
    end

    # override this method in a subclass to provide customized preloading behavior
    def preload(records)
      values = args.fetch(:values).call(records)
      records.each do |record|
        value = values[record.id]
        record._set_custom_preloaded_value(name, value)
      end
    end

  end
end
