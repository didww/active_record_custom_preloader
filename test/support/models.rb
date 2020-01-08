class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Comment < ApplicationRecord
  belongs_to :user, class_name: 'User'
end

class ApiAccess < ApplicationRecord
  belongs_to :user, class_name: 'User'
end

class Pricelist < ApplicationRecord
  has_many :users, class_name: 'User'
end

class User < ApplicationRecord
  # columns id, name, pricelist_id, department_ids
  has_many :comments, class_name: 'Comment', dependent: :delete_all
  has_one :api_access, class_name: 'ApiAccess', dependent: :delete
  belongs_to :pricelist, class_name: 'Pricelist', required: false
  serialize :department_ids # because sqlite can't store arrays
  add_custom_loader :_simple, class_name: 'SimpleUserPreloader'
  add_custom_loader :_departments, class_name: 'UserDepartmentsPreloader'
end

class Department < ApplicationRecord
  # columns id, name
end
