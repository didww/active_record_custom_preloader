require 'active_record_custom_preloader/version'
require 'active_record_custom_preloader/preloader'
require 'active_record_custom_preloader/preload_with_options'
require 'active_record_custom_preloader/associations_preloader'
require 'active_record_custom_preloader/model_patch'
require 'active_record_custom_preloader/relation_patch'
require 'active_record_custom_preloader/with_multiple_foreign_keys_loading'

module ActiveRecordCustomPreloader
  class Error < StandardError
  end
  # Your code goes here...
end
