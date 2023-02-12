[![CircleCI](https://circleci.com/gh/ryz310/redis-objects-periodical.svg?style=svg)](https://circleci.com/gh/ryz310/redis-objects-periodical) [![Gem Version](https://badge.fury.io/rb/redis-objects-periodical.svg)](https://badge.fury.io/rb/redis-objects-periodical) [![Maintainability](https://api.codeclimate.com/v1/badges/deebb6c406c306a6f337/maintainability)](https://codeclimate.com/github/ryz310/redis-objects-periodical/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/deebb6c406c306a6f337/test_coverage)](https://codeclimate.com/github/ryz310/redis-objects-periodical/test_coverage)

# Redis::Objects::Periodical

This is a gem which extends [Redis::Objects](https://github.com/nateware/redis-objects) gem. Once install this gem, you can use the periodical counter, the periodical set, etc. in addition to the standard features of Redis::Objects. These counters and sets are useful for measuring conversions, implementing API rate limiting, MAU, DAU, and more.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis-objects-periodical'
```

If you want to know about installation and standard usage, please see Redis::Objects' GitHub page.

## Usage

`daily_counter` and `daily_set` automatically creates keys that are unique to each object, in the format:

```
model_name:id:field_name:yyyy-mm-dd
```

I recommend using with `expireat` option.
For illustration purposes, consider this stub class:

```rb
class Homepage
  include Redis::Objects

  daily_counter :pv, expireat: -> { Time.now + 2_678_400 } # about a month
  daily_hash_key :browsing_history, expireat: -> { Time.now + 2_678_400 } # about a month
  daily_set :dau, expireat: -> { Time.now + 2_678_400 } # about a month
  daily_value :cache, expireat: -> { Time.now + 2_678_400 } # about a month

  def id
    1
  end
end

# 2021-04-01
homepage = Homepage.new
homepage.id # 1

homepage.pv.increment
homepage.pv.increment
homepage.pv.increment
puts homepage.pv.value # 3

# 2021-04-02 (next day)
puts homepage.pv.value # 0
homepage.pv.increment
homepage.pv.increment
puts homepage.pv.value # 2

start_date = Date.new(2021, 4, 1)
end_date = Date.new(2021, 4, 2)
homepage.pv.range(start_date, end_date) # [3, 2]
```

### Periodical Counters

The periodical counters automatically switches the save destination when the date changes.
You can access past dates counted values like Ruby arrays:

```rb
# 2021-04-01
homepage.pv.increment(3)

# 2021-04-02 (next day)
homepage.pv.increment(2)

# 2021-04-03 (next day)
homepage.pv.increment(5)

homepage.pv[Date.new(2021, 4, 1)] # => 3
homepage.pv[Date.new(2021, 4, 1), 3] # => [3, 2, 5]
homepage.pv[Date.new(2021, 4, 1)..Date.new(2021, 4, 2)] # => [3, 2]

homepage.pv.delete_at(Date.new(2021, 4, 1))
homepage.pv.range(Date.new(2021, 4, 1), Date.new(2021, 4, 3)) # => [0, 2, 5]
homepage.pv.at(Date.new(2021, 4, 2)) # => #<Redis::Counter key="homepage:1:pv:2021-04-02">
homepage.pv.at(Date.new(2021, 4, 2)).value # 2
```

#### Periodical Counters Family

- `annual_counter`
  - Key format: `model_name:id:field_name:yyyy`
  - Redis is a highly volatile key-value store, so I don't recommend using it.
- `monthly_counter`
  - Key format: `model_name:id:field_name:yyyy-mm`
- `weekly_counter`
  - Key format: `model_name:id:field_name:yyyyWw`
- `daily_counter`
  - Key format: `model_name:id:field_name:yyyy-mm-dd`
- `hourly_counter`
  - Key format: `model_name:id:field_name:yyyy-mm-ddThh`
- `minutely_counter`
  - Key format: `model_name:id:field_name:yyyy-mm-ddThh:mi`

### Periodical Values

The periodical values automatically switches the save destination when the date changes.

```rb
# 2021-04-01
homepage.cache.value = 'a'

# 2021-04-02 (next day)
homepage.cache.value = 'b'

# 2021-04-03 (next day)
homepage.cache.value = 'c'

homepage.cache[Date.new(2021, 4, 1)] # => 'a'
homepage.cache[Date.new(2021, 4, 1), 3] # => ['a', 'b', 'c']
homepage.cache[Date.new(2021, 4, 1)..Date.new(2021, 4, 2)] # => ['a', 'b']

homepage.cache.delete_at(Date.new(2021, 4, 1))
homepage.cache.range(Date.new(2021, 4, 1), Date.new(2021, 4, 3)) # => [nil, 'b', 'c']
homepage.cache.at(Date.new(2021, 4, 2)) # => #<Redis::Value key="homepage:1:cache:2021-04-02">
homepage.cache.at(Date.new(2021, 4, 2)).value # 'b'
```

#### Periodical Values Family

- `annual_value`
  - Key format: `model_name:id:field_name:yyyy`
  - Redis is a highly volatile key-value store, so I don't recommend using it.
- `monthly_value`
  - Key format: `model_name:id:field_name:yyyy-mm`
- `weekly_value`
  - Key format: `model_name:id:field_name:yyyyWw`
- `daily_value`
  - Key format: `model_name:id:field_name:yyyy-mm-dd`
- `hourly_value`
  - Key format: `model_name:id:field_name:yyyy-mm-ddThh`
- `minutely_value`
  - Key format: `model_name:id:field_name:yyyy-mm-ddThh:mi`

### Periodical Hashes

The periodical hashes also automatically switches the save destination when the date changes.

```rb
# 2021-04-01
homepage.browsing_history.incr('item1')
homepage.browsing_history.incr('item2')
homepage.browsing_history.incr('item2')
puts homepage.browsing_history.all # { 'item1' => '1', 'item2' => '2' }

# 2021-04-02 (next day)
puts homepage.browsing_history.all # {}

homepage.browsing_history.bulk_set('item1' => 3, 'item3' => 5)
puts homepage.browsing_history.all # { 'item1' => '3', 'item3' => '5' }

# 2021-04-03 (next day)
homepage.browsing_history.incr('item2')
homepage.browsing_history.incr('item4')
puts homepage.browsing_history.all # { 'item2' => '1', 'item4' => '1' }

homepage.browsing_history[Date.new(2021, 4, 1)] # => { 'item1' => '1', 'item2' => '2' }
homepage.browsing_history[Date.new(2021, 4, 1), 3] # => { 'item1' => '4', 'item2' => '3', 'item3' => '5', 'item4' => '1' }
homepage.browsing_history[Date.new(2021, 4, 1)..Date.new(2021, 4, 2)] # => { 'item1' => '4', 'item2' => '2', 'item3' => '5' }

homepage.browsing_history.delete_at(Date.new(2021, 4, 1))
homepage.browsing_history.range(Date.new(2021, 4, 1), Date.new(2021, 4, 3)) # => { 'item1' => '3', 'item2' => '1', 'item3' => '5', 'item4' => '1' }
homepage.browsing_history.at(Date.new(2021, 4, 2)) # => #<Redis::HashKey key="homepage:1:browsing_history:2021-04-02">
homepage.browsing_history.at(Date.new(2021, 4, 2)).all # { 'item1' => '3', 'item3' => '5' }
```

#### Periodical Hashes Family

- `annual_hash_key`
  - Key format: `model_name:id:field_name:yyyy`
  - Redis is a highly volatile key-value store, so I don't recommend using it.
- `monthly_hash_key`
  - Key format: `model_name:id:field_name:yyyy-mm`
- `weekly_hash_key`
  - Key format: `model_name:id:field_name:yyyyWw`
- `daily_hash_key`
  - Key format: `model_name:id:field_name:yyyy-mm-dd`
- `hourly_hash_key`
  - Key format: `model_name:id:field_name:yyyy-mm-ddThh`
- `minutely_hash_key`
  - Key format: `model_name:id:field_name:yyyy-mm-ddThh:mi`

### Periodical Sets

The periodical sets also automatically switches the save destination when the date changes.

```rb
# 2021-04-01
homepage.dau << 'user1'
homepage.dau << 'user2'
homepage.dau << 'user1' # dup ignored
puts homepage.dau.members # ['user1', 'user2']
puts homepage.dau.length # 2
puts homepage.dau.count # alias of #length

# 2021-04-02 (next day)
puts homepage.dau.members # []

homepage.dau.merge('user2', 'user3')
puts homepage.dau.members # ['user2', 'user3']

# 2021-04-03 (next day)
homepage.dau.merge('user4')

homepage.dau[Date.new(2021, 4, 1)] # => ['user1', 'user2']
homepage.dau[Date.new(2021, 4, 1), 3] # => ['user1', 'user2', 'user3', 'user4']
homepage.dau[Date.new(2021, 4, 1)..Date.new(2021, 4, 2)] # => ['user1', 'user2', 'user3']

homepage.dau.delete_at(Date.new(2021, 4, 1))
homepage.dau.range(Date.new(2021, 4, 1), Date.new(2021, 4, 3)) # => ['user2', 'user3', 'user4']
homepage.dau.at(Date.new(2021, 4, 2)) # => #<Redis::Set key="homepage:1:dau:2021-04-02">
homepage.dau.at(Date.new(2021, 4, 2)).members # ['user2', 'user3']
```

#### Periodical Sets Family

- `annual_set`
  - Key format: `model_name:id:field_name:yyyy`
  - Redis is a highly volatile key-value store, so I don't recommend using it.
- `monthly_set`
  - Key format: `model_name:id:field_name:yyyy-mm`
- `weekly_set`
  - Key format: `model_name:id:field_name:yyyyWw`
- `daily_set`
  - Key format: `model_name:id:field_name:yyyy-mm-dd`
- `hourly_set`
  - Key format: `model_name:id:field_name:yyyy-mm-ddThh`
- `minutely_set`
  - Key format: `model_name:id:field_name:yyyy-mm-ddThh:mi`

### Timezone

This gem follows Ruby process' time zone, but if you extends Time class by ActiveSupport (e.g. `Time.current`), follows Rails process' timezone.

## Development

The development environment for this gem is configured with docker-compose.
Please use the following command:

    $ docker-compose up -d
    $ docker-compose run --rm ruby bundle
    $ docker-compose run --rm ruby rspec .
    $ docker-compose run --rm ruby rubocop -a

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/redis-objects-periodical. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/redis-objects-periodical/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Redis::Objects::Daily::Counter project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/redis-objects-periodical/blob/master/CODE_OF_CONDUCT.md).
