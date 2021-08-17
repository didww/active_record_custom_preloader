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
  has_many :prices, class_name: 'Price'
end

class PriceBundle < ApplicationRecord
  has_many :users, class_name: 'User'
  has_many :prices, class_name: 'Price'
end

class Price < ApplicationRecord
  belongs_to :pricelist, class_name: 'Pricelist'
  belongs_to :price_bundle, class_name: 'PriceBundle'
  add_custom_loader :_simple, class_name: 'SimplePreloader'
end

class Discount < ApplicationRecord
  belongs_to :pricelist, class_name: 'Pricelist'
  belongs_to :price_bundle, class_name: 'PriceBundle'
  add_custom_loader :_simple, class_name: 'SimplePreloader'
end

class User < ApplicationRecord
  # columns id, name, pricelist_id, department_ids
  has_many :comments, class_name: 'Comment', dependent: :delete_all
  has_one :api_access, class_name: 'ApiAccess', dependent: :delete
  belongs_to :pricelist, class_name: 'Pricelist', required: false
  belongs_to :price_bundle, class_name: 'PriceBundle', required: false
  serialize :department_ids # because sqlite can't store arrays
  add_custom_loader :_simple, class_name: 'SimplePreloader'
  add_custom_loader :_departments, class_name: 'UserDepartmentsPreloader'
  add_custom_loader :_prices, class_name: 'UserPricesPreloader'
  add_custom_loader :_discount, class_name: 'UserDiscountPreloader'
end

class Department < ApplicationRecord
  # columns id, name
end
