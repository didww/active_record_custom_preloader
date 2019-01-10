$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'active_support/all'
require 'active_record'
require 'active_record_custom_preloader/railtie'

require 'support/connection_and_schema'
require 'support/preloaders'
require 'support/models'

require 'minitest/autorun'
