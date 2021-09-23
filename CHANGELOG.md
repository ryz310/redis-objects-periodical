# Change log

## v0.3.0 (Sep 23, 2021)

### Feature

* [#7](https://github.com/ryz310/redis-object-daily-counter/pull/7) Add daily set ([@ryz310](https://github.com/ryz310))

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

* [#7](https://github.com/ryz310/redis-object-daily-counter/pull/7) Add daily set ([@ryz310](https://github.com/ryz310))

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

* [#3](https://github.com/ryz310/redis-objects-daily-counter/pull/3) Support time zone ([@ryz310](https://github.com/ryz310))
* [#4](https://github.com/ryz310/redis-objects-daily-counter/pull/4) Add daily counter family ([@ryz310](https://github.com/ryz310))
    * `annual_counter`
    * `monthly_counter`
    * `weekly_counter`
    * `hourly_counter`
    * `minutely_counter`

### Misc

* [#2](https://github.com/ryz310/redis-objects-daily-counter/pull/2) Install circle ci ([@ryz310](https://github.com/ryz310))

## v0.1.0 (Sep 12, 2021)

* The first release :tada:
