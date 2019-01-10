class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class User < ApplicationRecord
  # columns id, name, pricelist_id
  add_custom_loader :_simple, class_name: 'SimpleUserPreloader'
end
