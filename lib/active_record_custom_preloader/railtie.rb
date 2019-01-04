require 'active_record'
require 'active_record_custom_preloader'

ActiveRecord::Base.include ActiveRecordCustomPreloader::ModelPatch
ActiveRecord::Relation.include ActiveRecordCustomPreloader::RelationPatch
