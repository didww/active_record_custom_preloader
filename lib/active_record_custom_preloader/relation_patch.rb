# frozen_string_literal: true
require 'active_support/concern'

module ActiveRecordCustomPreloader
  module RelationPatch
    extend ActiveSupport::Concern

    included do
      private

      def build_preloader
        ActiveRecordCustomPreloader::AssociationsPreloader.new
      end
    end

    # custom preload with optional args
    # usage:
    #
    #   class IncomingStatisticPreloader < ActiveRecordCustomPreloader::Preloader
    #     def preload(records)
    #       StatsApi.fetch(:incoming, group_by: args.fetch(:group_by))
    #     end
    #   end
    #
    #   class OutgoingStatisticPreloader < ActiveRecordCustomPreloader::Preloader
    #     def preload(records)
    #       ids = records.map(&:id)
    #       api_result = StatsApi.fetch(:incoming, person_ids: ids, group: args.fetch(:group))
    #       values = api_result.group_by(&:person_id)
    #       records.each do |record|
    #         value = values[record.id] || []
    #         record._set_custom_preloaded_value(name, value)
    #       end
    #     end
    #   end
    #
    #   class Person < ActiveRecord::Base
    #     add_loader :_incoming_stats, class_name: 'IncomingStatisticPreloader'
    #     add_loader :_outgoing_stats, class_name: 'OutgoingStatisticPreloader'
    #   end
    #
    #   Person.limit(10).custom_preload(:_incoming_stats, :_outgoing_stats, group: 'hour')
    #   # is syntax sugar for
    #   Person.limit(10).preload(
    #       ActiveRecordCustomPreloader::PreloadWithOptions.new(:_incoming_stats, group: 'hour'),
    #       ActiveRecordCustomPreloader::PreloadWithOptions.new(:_outgoing_stats, group: 'hour')
    #   )
    #
    def custom_preload(*names)
      args = names.extract_options!
      preloads = names.map { |name| PreloadWithOptions.new(name, args) }
      preload(*preloads)
    end
  end
end
