# Change log

## v0.7.0 (Feb 12, 2023)

### Feature
### Bugfix
### Security
### Breaking Change
### Rubocop Challenge
### Dependabot
### Misc

* [#128](https://github.com/ryz310/redis-object-daily-counter/pull/128) Periodical::Value ([@ryz310](https://github.com/ryz310))

## v0.6.0 (Feb 12, 2023)

### Feature

- [#125](https://github.com/ryz310/redis-object-daily-counter/pull/125) Support Ruby 3.2 ([@ryz310](https://github.com/ryz310))

### Rubocop Challenge

- [#104](https://github.com/ryz310/redis-object-daily-counter/pull/104) Style/RedundantStringEscape-20221214233055 ([@ryz310](https://github.com/ryz310))
- [#124](https://github.com/ryz310/redis-object-daily-counter/pull/124) Re-generate .rubocop_todo.yml with RuboCop v1.45.1 ([@ryz310](https://github.com/ryz310))

### Dependabot

- [#70](https://github.com/ryz310/redis-object-daily-counter/pull/70) Bump rspec from 3.11.0 to 3.12.0 ([@ryz310](https://github.com/ryz310))
- [#101](https://github.com/ryz310/redis-object-daily-counter/pull/101) Bump timecop from 0.9.5 to 0.9.6 ([@ryz310](https://github.com/ryz310))
- [#109](https://github.com/ryz310/redis-object-daily-counter/pull/109) Bump rubocop-performance from 1.15.1 to 1.15.2 ([@ryz310](https://github.com/ryz310))
- [#110](https://github.com/ryz310/redis-object-daily-counter/pull/110) Bump simplecov from 0.21.2 to 0.22.0 ([@ryz310](https://github.com/ryz310))
- [#116](https://github.com/ryz310/redis-object-daily-counter/pull/116) Bump rubocop-rspec from 2.18.0 to 2.18.1 ([@ryz310](https://github.com/ryz310))
- [#122](https://github.com/ryz310/redis-object-daily-counter/pull/122) Bump rubocop-performance from 1.15.2 to 1.16.0 ([@ryz310](https://github.com/ryz310))

## v0.5.0 (Sep 29, 2022)

### Feature

- [#34](https://github.com/ryz310/redis-object-daily-counter/pull/34) Enhanced type casting from Time to Date ([@ryz310](https://github.com/ryz310))

Enhances casting from `Time` to `Date`.

#### Before

```rb
homepage = Homepage.new
homepage.daily_active_users[Date.new(2021, 4, 1)] # OK
homepage.daily_active_users[Time.local(2021, 4, 1, 0, 0, 0)] # Error!
```

#### After

```rb
homepage = Homepage.new
homepage.daily_active_users[Date.new(2021, 4, 1)] # OK
homepage.daily_active_users[Time.local(2021, 4, 1, 0, 0, 0)] # OK
```

### Misc

- [#25](https://github.com/ryz310/redis-object-daily-counter/pull/25) Remove needless files ([@ryz310](https://github.com/ryz310))

## v0.4.1 (Jul 27, 2022)

### Misc

- [#22](https://github.com/ryz310/redis-objects-periodical/pull/22) Rename from redis-object-daily-counter to redis-objects-periodical ([@ryz310](https://github.com/ryz310))

## v0.4.0 (Jul 26, 2022)

### Feature

- [#17](https://github.com/ryz310/redis-objects-periodical/pull/17) Support `Redis::HashKey` as a recurring object ([@ryz310](https://github.com/ryz310))

### Breaking Change

- [#18](https://github.com/ryz310/redis-objects-periodical/pull/18) Bump up Ruby 3.1 and drop support Ruby 2.6 ([@ryz310](https://github.com/ryz310))

### Dependabot

- [#16](https://github.com/ryz310/redis-objects-periodical/pull/16) Bump yard from 0.9.26 to 0.9.28 ([@ryz310](https://github.com/ryz310))
- [#15](https://github.com/ryz310/redis-objects-periodical/pull/15) Bump rspec_junit_formatter from 0.4.1 to 0.5.1 ([@ryz310](https://github.com/ryz310))
- [#13](https://github.com/ryz310/redis-objects-periodical/pull/13) Bump rspec from 3.10.0 to 3.11.0 ([@ryz310](https://github.com/ryz310))
- [#14](https://github.com/ryz310/redis-objects-periodical/pull/14) Bump timecop from 0.9.4 to 0.9.5 ([@ryz310](https://github.com/ryz310))
- [#12](https://github.com/ryz310/redis-objects-periodical/pull/12) Bump redis-objects from 1.5.1 to 1.7.0 ([@ryz310](https://github.com/ryz310))

### Misc

- [#19](https://github.com/ryz310/redis-objects-periodical/pull/19) Reduce similar source codes with meta programming ([@ryz310](https://github.com/ryz310))

## v0.3.0 (Sep 23, 2021)

### Feature

- [#7](https://github.com/ryz310/redis-objects-periodical/pull/7) Add daily set ([@ryz310](https://github.com/ryz310))

> You can use `daily_set` in addition to the standard features of Redis::Objects.
>
> ```rb
> class Homepage
>   include Redis::Objects
>
>   daily_set :dau, expireat: -> { Time.now + 2_678_400 } # about a month
>
>   def id
>     1
>   end
> end
>
> # 2021-04-01
> homepage.dau << 'user1'
> homepage.dau << 'user2'
> homepage.dau << 'user1' # dup ignored
> puts homepage.dau.members # ['user1', 'user2']
> puts homepage.dau.length # 2
> puts homepage.dau.count # alias of #length
>
> # 2021-04-02 (next day)
> puts homepage.dau.members # []
> homepage.dau.merge('user2', 'user3')
> puts homepage.dau.members # ['user2', 'user3']
>
> # 2021-04-03 (next day)
> homepage.dau.merge('user4')
>
> homepage.dau[Date.new(2021, 4, 1)] # => ['user1', 'user2']
> homepage.dau[Date.new(2021, 4, 1), 3] # => ['user1', 'user2', 'user3', 'user4']
> homepage.dau[Date.new(2021, 4, 1)..Date.new(2021, 4, 2)] # => ['user1', 'user2', 'user3']
>
> homepage.dau.delete_at(Date.new(2021, 4, 1))
> homepage.dau.range(Date.new(2021, 4, 1), Date.new(2021, 4, 3)) # => ['user2', 'user3', 'user4']
> homepage.dau.at(Date.new(2021, 4, 2)) # => #<Redis::Set key="homepage:1:dau:2021-04-02">
> homepage.dau.at(Date.new(2021, 4, 2)).members # ['user2', 'user3']
> ```

### Breaking Change

- [#7](https://github.com/ryz310/redis-objects-periodical/pull/7) Add daily set ([@ryz310](https://github.com/ryz310))

> Rename the method from #delete to #delete_at a73251f
>
> ```rb
> # Before
> homepage.pv.delete(Date.new(2021, 4, 1))
>
> # After
> homepage.pv.delete_at(Date.new(2021, 4, 1))
> ```
>
> Modify returning value of RecurringAtIntervals#at 1c8cc79
>
> ```rb
> # Before
> homepage.pv.at(Date.new(2021, 4, 2)) # => 2
>
> # After
> homepage.pv.at(Date.new(2021, 4, 2)) # => #<Redis::Counter key="homepage:1:pv:2021-04-02">
> ```

## v0.2.0 (Sep 20, 2021)

### Feature

- [#3](https://github.com/ryz310/redis-objects-periodical/pull/3) Support time zone ([@ryz310](https://github.com/ryz310))
- [#4](https://github.com/ryz310/redis-objects-periodical/pull/4) Add daily counter family ([@ryz310](https://github.com/ryz310))
  - `annual_counter`
  - `monthly_counter`
  - `weekly_counter`
  - `hourly_counter`
  - `minutely_counter`

### Misc

- [#2](https://github.com/ryz310/redis-objects-periodical/pull/2) Install circle ci ([@ryz310](https://github.com/ryz310))

## v0.1.0 (Sep 12, 2021)

- The first release :tada:
