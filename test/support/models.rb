class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class User < ApplicationRecord
  # columns id, name, pricelist_id, department_ids
  serialize :department_ids # because sqlite can't store arrays
  add_custom_loader :_simple, class_name: 'SimpleUserPreloader'
  add_custom_loader :_departments, class_name: 'UserDepartmentsPreloader'
end

class Department < ApplicationRecord
  # columns id, name
end
