# ActiveRecordCustomPreloader

custom preloader for ActiveRecord model

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_record_custom_preloader'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_record_custom_preloader

## Usage

```ruby
class Person < ActiveRecord::Base
  add_custom_loader :_stats, class_name: 'StatsPreloader'
end

class StatsPreloader < ActiveRecordCustomerPreloader::Preloader
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/senid231/active_record_custom_preloader. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveRecordCustomPreloader project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/active_record_custom_preloader/blob/master/CODE_OF_CONDUCT.md).
