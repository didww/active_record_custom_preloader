module ActiveRecordCustomPreloader
  class PreloadWithOptions
    attr_reader :name, :options
    def initialize(name, options = {})
      @name = name
      @options = options
    end

    def loader_for(klass)
      klass.custom_loader_for(name, options)
    end
  end
end
