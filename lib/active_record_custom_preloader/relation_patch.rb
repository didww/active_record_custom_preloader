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
  end
end
