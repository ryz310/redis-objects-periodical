[![CI](https://github.com/ryz310/redis-objects-periodical/actions/workflows/ci.yml/badge.svg)](https://github.com/ryz310/redis-objects-periodical/actions/workflows/ci.yml) [![Gem Version](https://badge.fury.io/rb/redis-objects-periodical.svg)](https://badge.fury.io/rb/redis-objects-periodical)
[![Maintainability](https://qlty.sh/gh/ryz310/projects/redis-objects-periodical/maintainability.svg)](https://qlty.sh/gh/ryz310/projects/redis-objects-periodical)
[![Code Coverage](https://qlty.sh/gh/ryz310/projects/redis-objects-periodical/coverage.svg)](https://qlty.sh/gh/ryz310/projects/redis-objects-periodical)

# Redis::Objects::Periodical

Extend [Redis::Objects](https://github.com/nateware/redis-objects) with counters,
values, sets, and hashes whose Redis keys are partitioned by period. Use them for
page views, active-user counts, rate-limiting data, and other periodical values.

## Installation

Ruby 3.3 or newer is required. Ruby 3.3, 3.4, and 4.0 are tested in CI.
The support policy follows stable Ruby branches receiving official normal or
security maintenance; preview releases are not supported. CI uses the latest
patch releases available in each supported series' CircleCI Ruby image.
See [Ruby's maintenance status](https://www.ruby-lang.org/en/downloads/branches/).

Ruby 2.7, 3.0, 3.1, and 3.2 are no longer supported. Applications using those
versions must upgrade Ruby before upgrading this gem, or remain on the last gem
release whose `required_ruby_version` permits their Ruby version.

Add this line to your application's Gemfile:

```ruby
gem 'redis-objects-periodical'
```

The gem accepts `redis-objects >= 1, < 3`. Development and CI lock
redis-objects 2.0.0. When upgrading from 1.x, review the
[compatibility, key-prefix, and migration notes](docs/usage.md#redisobjects-compatibility),
including connection setup, lock declarations, and existing Redis keys.

## Quick start

Configure the Redis connection as described in
[Redis::Objects](https://github.com/nateware/redis-objects), then declare a field:

```ruby
require 'redis-objects-periodical'

class Homepage
  include Redis::Objects

  daily_counter :pv, expireat: -> { Time.now + 2_678_400 } # about a month

  def id
    1
  end
end

homepage = Homepage.new
# On 2021-04-01:
homepage.pv.increment(3)
homepage.pv.value # => 3

# On 2021-04-02, calling the field accessor selects the new day's key:
homepage.pv.value # => 0
homepage.pv.increment(2)
homepage.pv.range(Date.new(2021, 4, 1), Date.new(2021, 4, 2)) # => [3, 2]
```

Keys are unique to the model, its ID, field, and period. This daily counter uses
`homepage:1:pv:2021-04-01`. Each field accessor creates a new periodical object;
an object retained in a variable keeps its original key across period boundaries.
Use an appropriate expiration option to limit retained period keys.

## Available periods and types

Combine one of `annual`, `monthly`, `weekly`, `daily`, `hourly`, or `minutely`
with one of these field types:

| Type | Daily declaration | Single-period result | Multi-period result |
| --- | --- | --- | --- |
| Counter | `daily_counter` | Integer, missing as `0` | Array of integers |
| Value | `daily_value` | Stored value, missing as `nil` | Array of values |
| Set | `daily_set` | Members, missing as `[]` | Union of members |
| Hash | `daily_hash_key` | Hash, missing as `{}` | Hash with combined field values |

See the [usage guide](docs/usage.md) for declarations, key suffixes, weekly
year-boundary behavior, date/time arguments, aggregation, expiration, and timezone
selection. Rails/ActiveSupport is optional.

## Development and maintenance

- [Contributing](CONTRIBUTING.md): Docker setup, isolated Compose projects,
  specs, lint, builds, CI, and optional ActiveSupport verification.
- [Maintaining](docs/maintaining.md): dependency updates, auto-merge, coverage
  configuration, releases, scheduled maintenance, and CircleCI cutover/rollback.
- [Agent guidance](AGENTS.md): repository workflow and compatibility constraints.
- [Changelog](CHANGELOG.md): released changes.

## Contributing

Bug reports and pull requests are welcome on
[GitHub](https://github.com/ryz310/redis-objects-periodical).
Track unresolved bugs, improvements, and decisions in
[GitHub Issues](https://github.com/ryz310/redis-objects-periodical/issues).
See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow.

## License and code of conduct

The gem is available under the [MIT License](LICENSE.txt).
Everyone interacting with the Redis::Objects::Periodical project is expected to
follow the [code of conduct](CODE_OF_CONDUCT.md).
