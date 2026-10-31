# Change log

## v0.8.0 (Oct 29, 2026)

### Bugfix

- [#264](https://github.com/ryz310/redis-objects-periodical/pull/264) Fix weekly keys for weeks spanning a year boundary across counters, values, sets, and hashes. ([@ashimomura](https://github.com/ashimomura))

### Breaking Change

- [#291](https://github.com/ryz310/redis-objects-periodical/pull/291) Require Ruby 3.3 or newer; drop Ruby 2.7, 3.0, 3.1, and 3.2 support and test Ruby 3.3, 3.4, and 4.0. Applications on older Ruby versions must upgrade Ruby or remain on a compatible gem release. ([@ryz310](https://github.com/ryz310))
- [#264](https://github.com/ryz310/redis-objects-periodical/pull/264) Derive weekly keys from the Monday of the requested week. For example, January 1, 2022 now uses `2021W52` instead of `2022W00`. Existing January `W00` data is not migrated and affected accessors will select the preceding December key after upgrading. Assess retained weekly data and any application-specific migration before deployment. The keys still use `%Y`/`%W`, not ISO week-year numbering. ([@ashimomura](https://github.com/ashimomura))

### Rubocop Challenge

- [#192](https://github.com/ryz310/redis-objects-periodical/pull/192) Apply Layout/ExtraSpacing and Performance/StringIdentifierArgument corrections. ([@ryz310](https://github.com/ryz310))

### Dependabot

- [#288](https://github.com/ryz310/redis-objects-periodical/pull/288) Bump rubocop from 1.76.2 to 1.92.1 ([@ryz310](https://github.com/ryz310))
- [#277](https://github.com/ryz310/redis-objects-periodical/pull/277) Bump rubocop-rspec from 3.6.0 to 3.10.2 ([@ryz310](https://github.com/ryz310))
- [#281](https://github.com/ryz310/redis-objects-periodical/pull/281) Bump yard from 0.9.37 to 0.9.45 ([@ryz310](https://github.com/ryz310))
- [#289](https://github.com/ryz310/redis-objects-periodical/pull/289) Bump rubocop-performance from 1.25.0 to 1.27.0 ([@ryz310](https://github.com/ryz310))
- [#270](https://github.com/ryz310/redis-objects-periodical/pull/270) Bump timecop from 0.9.10 to 0.9.11 ([@ryz310](https://github.com/ryz310))
- [#268](https://github.com/ryz310/redis-objects-periodical/pull/268) Bump rake from 13.3.0 to 13.4.2 ([@ryz310](https://github.com/ryz310))
- [#273](https://github.com/ryz310/redis-objects-periodical/pull/273) Bump rspec from 3.13.1 to 3.13.2 ([@ryz310](https://github.com/ryz310))
- [#286](https://github.com/ryz310/redis-objects-periodical/pull/286) Bump actions/checkout from 6.1.0 to 7.0.1 ([@ryz310](https://github.com/ryz310))
- [#310](https://github.com/ryz310/redis-objects-periodical/pull/310) Bump rspec_junit_formatter from 0.6.2 to 0.8.0 ([@ryz310](https://github.com/ryz310))
- [#311](https://github.com/ryz310/redis-objects-periodical/pull/311) Bump simplecov from 0.22.0 to 1.3.2 ([@ryz310](https://github.com/ryz310))
- [#293](https://github.com/ryz310/redis-objects-periodical/pull/293) Bump dependabot/fetch-metadata from 3.0.0 to 3.1.0 ([@ryz310](https://github.com/ryz310))
- [#294](https://github.com/ryz310/redis-objects-periodical/pull/294) Bump actions/github-script from 8.0.0 to 9.0.0 ([@ryz310](https://github.com/ryz310))

### Misc

- [#283](https://github.com/ryz310/redis-objects-periodical/pull/283) Restore CI while retiring unavailable Code Climate reporting. ([@ryz310](https://github.com/ryz310))
- [#284](https://github.com/ryz310/redis-objects-periodical/pull/284) Migrate combined SimpleCov coverage reporting to Qlty. ([@ryz310](https://github.com/ryz310))
- [#282](https://github.com/ryz310/redis-objects-periodical/pull/282) Add agent guidance and repair the Docker development setup. ([@ryz310](https://github.com/ryz310))
- [#285](https://github.com/ryz310/redis-objects-periodical/pull/285) Migrate CI, release publishing, and scheduled maintenance from CircleCI to SHA-pinned GitHub Actions; document external cutover and rollback requirements. ([@ryz310](https://github.com/ryz310))
- [#290](https://github.com/ryz310/redis-objects-periodical/pull/290) Add guarded Dependabot auto-merge and isolated ActiveSupport timezone verification; retain plain-Ruby coverage and optional ActiveSupport support. ([@ryz310](https://github.com/ryz310))
- [#304](https://github.com/ryz310/redis-objects-periodical/pull/304) Reconcile workflow-owned auto-merge reservations on rejection and guard the clean-status merge fallback. ([@ryz310](https://github.com/ryz310))
- [#305](https://github.com/ryz310/redis-objects-periodical/pull/305) Correct Actions ecosystem metadata matching for Dependabot policy. ([@ryz310](https://github.com/ryz310))
- [#301](https://github.com/ryz310/redis-objects-periodical/pull/301) Allow isolated Compose projects to run concurrently without publishing the Redis host port. ([@ryz310](https://github.com/ryz310))
- [#303](https://github.com/ryz310/redis-objects-periodical/pull/303) Pin development Redis to the immutable CI image digest. ([@ryz310](https://github.com/ryz310))
- [#302](https://github.com/ryz310/redis-objects-periodical/pull/302) Fail timezone CI when expected integration examples are missing, duplicated, unexpected, or pending. ([@ryz310](https://github.com/ryz310))
- [#306](https://github.com/ryz310/redis-objects-periodical/pull/306) Separate public usage, contributor, maintainer, and dated verification documentation. ([@ryz310](https://github.com/ryz310))
- [#308](https://github.com/ryz310/redis-objects-periodical/pull/308) Remove the additional Dependabot auto-merge enable variable. ([@ryz310](https://github.com/ryz310))
- [#309](https://github.com/ryz310/redis-objects-periodical/pull/309) Manage optional ActiveSupport dependencies across both lockfiles with Dependabot. ([@ryz310](https://github.com/ryz310))
- [#313](https://github.com/ryz310/redis-objects-periodical/pull/313) Add a repository-local Dependabot batch-maintenance skill. ([@ryz310](https://github.com/ryz310))

## v0.7.0 (Feb 12, 2023)

### Feature

- [#128](https://github.com/ryz310/redis-object-daily-counter/pull/128) Support`Redis::Value` as a periodical object ([@ryz310](https://github.com/ryz310))

> The periodical values automatically switches the save destination when the date changes.
>
> ```rb
> class Homepage
>   include Redis::Objects
>
>   daily_value :cache, expireat: -> { Time.now + 2_678_400 } # about a month
>
>   def id
>     1
>   end
> end
>
> homepage = Homepage.new
>
> # 2021-04-01
> homepage.cache.value = 'a'
>
> # 2021-04-02 (next day)
> homepage.cache.value = 'b'
>
> # 2021-04-03 (next day)
> homepage.cache.value = 'c'
>
> homepage.cache[Date.new(2021, 4, 1)] # => 'a'
> homepage.cache[Date.new(2021, 4, 1), 3] # => ['a', 'b', 'c']
> homepage.cache[Date.new(2021, 4, 1)..Date.new(2021, 4, 2)] # => ['a', 'b']
>
> homepage.cache.delete_at(Date.new(2021, 4, 1))
> homepage.cache.range(Date.new(2021, 4, 1), Date.new(2021, 4, 3)) # => [nil, 'b', 'c']
> homepage.cache.at(Date.new(2021, 4, 2)) # => #<Redis::Value key="homepage:1:cache:2021-04-02">
> homepage.cache.at(Date.new(2021, 4, 2)).value # 'b'
> ```

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
