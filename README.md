# ActiveRecordCustomPreloader

Custom preloader for ActiveRecord model.

Gem version `2.X.X` and `master` branch compatible with Rails `6.X.X` and upper.
For Rails `5.X.X` see branch `rails-5` and gem version `1.X.X`.

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'active_record_custom_preloader'
```

if you use Rails you should require `railtie.rb` file 
like this in `config/application.rb`:
```ruby
require 'active_record_custom_preloader/railtie'
```
or like this in `Gemfile`
```ruby
gem 'active_record_custom_preloader', require: 'active_record_custom_preloader/railtie'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_record_custom_preloader

## Usage

```ruby
require 'active_record_custom_preloader/railtie'

class Person < ActiveRecord::Base
  add_custom_loader :_stats, class_name: 'StatsPreloader'
end

class ApplicationPreloader < ActiveRecordCustomPreloader::Preloader
end

class StatsPreloader < ApplicationPreloader
  def preload(records)
    ids = records.map(&:id)
    values = CustomApi.fetch_stats_for(ids)
    records.each do |record|
      value = OpenStruct.new(values[record.id])
      record._set_custom_preloaded_value(name, value)
    end
  end
end

people = Person.all.preload(:_stats)
people.first._stats # will return value that was preloaded earlier

person = Person.find(1)
person._stats # will preload and return value
person._stats # will return value that was preloaded earlier
person.clear_custom_preloaded_value(:_stats) # will clear preloaded value for _stats
person._stats # will preload again and return value
```

you can use `ActiveRecordCustomPreloader::WithMultipleForeignKeysLoading` module
for preloading active_record models which are related to parent record by multiple keys
```ruby
require 'active_record_custom_preloader/railtie'

class Employee < ActiveRecord::Base
  # columns: id, name, department_id, position_id
  add_custom_loader :_contract, class_name: 'EmployeeContractPreloader'
end

class Contract < ActiveRecord::Base
  # columns: id, text, employee_department_id, position_id
end

class EmployeeContractPreloader < ActiveRecordCustomPreloader::Preloader
  include ActiveRecordCustomPreloader::WithMultipleForeignKeysLoading
  self.model_class_name = 'Contract'
  self.association_foreign_keys_names = [:employee_department_id, :position_id]

  def record_foreign_keys(record)
    [record.department_id, record.position_id]
  end
end
```

also you can use `ActiveRecordCustomPreloader::WithContextDependentLoading` module
for preloading active_record models which should be filtered by some external context
```ruby
require 'active_record_custom_preloader/railtie'

class User < ActiveRecord::Base
  # columns: id, name, pricelist_id
end

class Discount < ActiveRecord::Base
  # columns id, user_pricelist_id, product_id, percentage
end

class Product < ActiveRecord::Base
  # columns: id, name, price
  add_loader :_discount, class_name: 'ProductDiscountPreloader'
end

class ProductDiscountPreloader < ActiveRecordCustomPreloader::Preloader
  include ActiveRecordCustomPreloader::WithContextDependentLoading
  self.to_many = true
  self.association_group_key = :user_pricelist_id
  self.record_group_key = :pricelist_id

  def scoped_collection(records)
    product_ids = records.map(&:id)
    pricelist_id = args.fetch(:pricelist_id)
    Discount.where(user_pricelist_id: pricelist_id, product_id: product_ids)
  end
end

user = User.first
products = Product.limit(10).custom_preload(:_discount, pricelist_id: user.pricelist_id)
products.first._discount # will return array with zero or more Discount records
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/senid231/active_record_custom_preloader. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveRecordCustomPreloader project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/senid231/active_record_custom_preloader/blob/master/CODE_OF_CONDUCT.md).
