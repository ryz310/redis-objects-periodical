# Usage guide

[README](../README.md) introduces installation and a minimal counter example.
Configure the Redis connection through Redis::Objects before using these fields.

## Declarations and object lifetime

The examples below use these four fields. Each type's example illustrates a
separate sequence of writes to initially empty period keys.

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

homepage = Homepage.new
```

Each field accessor constructs a periodical object using the current time. Its
Redis key and cached current time are fixed at construction. Call the accessor
again after a period boundary to select the new key:

```ruby
counter = homepage.pv
# After midnight, counter still addresses the day on which it was constructed.
# homepage.pv creates a new object and selects the current day's key.
```

The `global: true` option also supports class-level fields, as in
`daily_counter :pv, global: true`. Standard Redis::Objects operations remain
available on each periodical object.

## Redis::Objects compatibility

The gem accepts `redis-objects >= 1, < 3`. The development and optional
ActiveSupport lockfiles select 2.0.0. Redis::Objects 2.x requires the `redis` Ruby
client gem `~> 5.0`; applications pinned to an older client must resolve that
dependency before upgrading.

When upgrading an application from redis-objects 1.x, also review the upstream
[2.0 README](https://github.com/nateware/redis-objects/blob/v2.0.0/README.md) and
[changelog](https://github.com/nateware/redis-objects/blob/v2.0.0/CHANGELOG.rdoc):

- Configure the connection explicitly with `Redis::Objects.redis = Redis.new(...)`
  or a supported connection pool. The `Redis.current` fallback was removed in
  2.0.0, although the upstream README still describes it.
- Rename model-level `lock :name` declarations to `redis_lock :name`.
  A lock object's `.lock` method remains available.
- For sets, including periodical sets, `add(nil)` now adds an empty string.
  With `marshal: true`, this changes a stored member from `nil` to `""`.
- If the application also uses ordinary `Redis::List` objects, `pop(n)` returns
  multiple elements in reverse order compared with 1.x. Multi-element `pop`
  and `shift` now use Redis commands requiring server version 6.2 or later.

### Key prefixes in redis-objects 2.x

Redis::Objects 2.x adds `Redis::Objects.prefix_style`, defaulting to `:legacy`.
Set it before the first key is generated:

```ruby
require 'redis-objects-periodical'

Redis::Objects.prefix_style = :modern
```

Periodical fields use the prefix selected by Redis::Objects and append the
same period suffix in either mode. For example, a `daily_counter :metric` on
`ResearchMigration::Entry0` with ID `7` uses these keys on 2026-10-31:

| Setting | Key |
| --- | --- |
| `:legacy` | `entry0:7:metric:2026-10-31` |
| `:modern` | `research_migration__entry0:7:metric:2026-10-31` |

This applies to all six periods and four types, including global fields (whose
ID component is empty). Top-level class prefixes remain the same in both modes.
Explicit `redis_prefix=`, field `key:`, and standalone constructor keys retain
their specified values. The setting also affects ordinary Redis::Objects fields.

The upstream class prefix is cached after first use, so changing `prefix_style`
later does not automatically change that class's keys. An existing periodical
object also keeps its original key. Configure the style consistently at startup.

Switching to `:modern` does not move existing data or fall back to legacy keys.
In 2.0.0, do not run the upstream `migrate_redis_legacy_keys` helper on models
with periodical fields: it drops period suffixes and can overwrite multiple
periods into one key. Retain `:legacy` for existing data until a migration that
preserves period suffixes and prevents overwrites has been planned separately.

## Periods and key formats

Combine any prefix below with `counter`, `value`, `set`, or `hash_key`.
The normal instance key has the prefix `model_name:id:field_name:`.

| Period prefix | Key suffix | Argument for historical access |
| --- | --- | --- |
| `annual_` | `yyyy` | `Date` or `Time` |
| `monthly_` | `yyyy-mm` | `Date` or `Time` |
| `weekly_` | `yyyyWww` | `Date` or `Time` |
| `daily_` | `yyyy-mm-dd` | `Date` or `Time` |
| `hourly_` | `yyyy-mm-ddThh` | `Time` |
| `minutely_` | `yyyy-mm-ddThh:mi` | `Time` |

Weekly keys first normalize the requested date to Monday, then format that
Monday using `%Y` and `%W`. They are not ISO week-year keys. For example,
2021-12-31 and 2022-01-01 both use `2021W52`. The year in the key can therefore
belong to December of the previous year. A configurable strategy remains an
unresolved decision in [Issue #265](https://github.com/ryz310/redis-objects-periodical/issues/265);
this guide describes the existing implementation.

Annual periods are not recommended when Redis is the only copy of long-term
history. Choose retention and expiration deliberately for every period.

## Shared historical operations

| Method | Behavior |
| --- | --- |
| `field[date_or_time]` or `slice` | Read one period's value |
| `field[start, length]` | Read/combine `length` successive periods |
| `field[start..finish]` | Pass an inclusive Range to the range reader |
| `field.range(start, finish)` | Read/combine successive cursors while cursor is at most `finish` |
| `field.delete_at(date_or_time)` | Delete one period's key |
| `field.at(date_or_time)` | Return a standard Redis::Objects object for that fixed key |

For the length form, zero returns an empty array (counter/value/set) or hash
(hash_key), and a negative length returns `nil`. Examples use inclusive ranges;
do not infer unsupported argument forms from the array-like method names.

Range iteration starts at the supplied start date/time and advances one interval
at a time; it does not first align the cursor to the calendar period boundary.
The end comparison is inclusive for that cursor, so a partial final interval may
not be visited. For example, a weekly range from Thursday 2021-04-01 to Monday
2021-04-05 reads only the week of March 29: its next cursor is April 8. Use
period-aligned endpoints when requesting complete calendar periods.

Counter and value ranges return arrays in period order. Set ranges return a
union; member order is not guaranteed. Hash ranges combine fields across periods:
unsigned integer strings are summed as integers, unsigned decimal strings are
summed as floats, and other repeated values are joined with commas. The numeric
aggregate remains a string. Missing periods contribute `0`, `nil`, `[]`, or `{}`
for counter, value, set, and hash respectively.

## Expiration

Use `expireat` as shown in the declarations to bound retention; its callable
returns the expiration time. The specs also exercise the upstream `expiration`
option with a duration in seconds. These options are provided through
Redis::Objects. Changing periods creates different keys; it does not itself
delete older period keys.

## Periodical Counters

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

## Periodical Values

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

## Periodical Hashes

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

## Periodical Sets

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

## Timezone

Without ActiveSupport, new periodical objects use `Time.now` in the Ruby
process timezone. If `Time.current` is available, they use it instead. With
ActiveSupport, `Time.zone` selects the application zone; when unset, its process
clock fallback applies. ActiveSupport is optional and is not a runtime dependency.

The [contributor guide](../CONTRIBUTING.md#optional-activesupport-integration)
describes the specific Ruby/ActiveSupport pair and boundary cases verified in CI;
it does not establish compatibility with every Rails release or timezone.
