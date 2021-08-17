# frozen_string_literal: true
require 'active_record'

module ActiveRecordCustomPreloader
  class AssociationsPreloader < ::ActiveRecord::Associations::Preloader
    private

    def preloaders_on(association, records, scope)
      assoc, nested_assocs = detect_custom_loader(association, records)
      if assoc
        preloaders_for_custom(assoc, records, nested_assocs, scope)
        return
      end

      super
    end

    # Preloads custom loader.
    # @param association [ActiveRecordCustomPreloader::PreloadWithOptions]
    # @param records [Array]
    def preloaders_for_custom(association, records, nested_assocs, scope)
      return if records.all? { |record| record.has_custom_preloaded_value?(association.name) }

      association.loader_for(records.first.class).preload(records)

      # Preload nested associations or custom loaders.
      # Allows to have nested preloading for custom loaders which load active record objects.
      if nested_assocs.any?
        preloaded_records = records.flat_map { |r| r.public_send(association.name) }.compact
        Array.wrap(nested_assocs).flat_map do |nested_assoc|
          preloaders_on(nested_assoc, preloaded_records, scope)
        end
      end
    end

    # Detects when custom loader should be used.
    # @param association [ActiveRecordCustomPreloader::PreloadWithOptions,Hash,Symbol,String]
    # @param records [Array]
    # @return [Array] ActiveRecordCustomPreloader::PreloadWithOptions object and nested preloads.
    def detect_custom_loader(association, records)
      return if records.size == 0

      klass = records.first.class
      return unless klass.respond_to?(:has_custom_loader?)

      if association.is_a?(PreloadWithOptions)
        [association, []]
      elsif association.is_a?(Hash) && association.keys.one? && klass.has_custom_loader?(association.keys.first)
        assoc = PreloadWithOptions.new(association.keys.first)
        preloads = Array.wrap(association.values.first).compact
        [assoc, preloads]
      elsif klass.has_custom_loader?(association)
        assoc = PreloadWithOptions.new(association)
        [assoc, []]
      end
    end

    # ActiveRecord preloading mechanism does not make preloads list unique,
    # so basically you can add same preload multiple times.
    # In case all collection has custom value loaded, we skip preloading process.
    # Same done at ActiveRecord::Associations::Preloader::AlreadyLoaded for associations.
    # @param association [ActiveRecordCustomPreloader::PreloadWithOptions]
    # @param records [Array]
    # @return [Boolean]
    def custom_loaded_all?(association, records)
      records.all? { |record| record.has_custom_preloaded_value?(association.name) }
    end
  end
end
