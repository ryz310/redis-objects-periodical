# Redis::Objects::Daily::Counter

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis-object-daily-counter'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install redis-object-daily-counter

## Usage

```rb
class Homepage
  include Redis::Objects

  daily_counter :pv_count

  def id
    1
  end
end

# 2021-04-01
hp = Homepage.new
hp.id # 1

hp.pv_count.increment
hp.pv_count.increment
hp.pv_count.increment
puts hp.pv_count.value # 3

# 2021-04-02 (next day)
puts hp.pv_count.value # 0
hp.pv_count.increment
hp.pv_count.increment
puts hp.pv_count.value # 2

start_date = Date.new(2021, 4, 1)
end_date = Date.new(2021, 4, 2)
hp.pv_count.range(start_date, end_date) # [3, 2]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

    $ docker-compose up -d
    $ docker-compose run --rm ruby bundle
    $ docker-compose run --rm ruby rspec .
    $ docker-compose run --rm ruby rubocop -a

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/redis-object-daily-counter. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/redis-object-daily-counter/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Redis::Objects::Daily::Counter project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/redis-object-daily-counter/blob/master/CODE_OF_CONDUCT.md).
