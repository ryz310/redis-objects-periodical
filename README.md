[![CI](https://github.com/ryz310/redis-objects-periodical/actions/workflows/ci.yml/badge.svg)](https://github.com/ryz310/redis-objects-periodical/actions/workflows/ci.yml) [![Gem Version](https://badge.fury.io/rb/redis-objects-periodical.svg)](https://badge.fury.io/rb/redis-objects-periodical)
[![Maintainability](https://qlty.sh/gh/ryz310/projects/redis-objects-periodical/maintainability.svg)](https://qlty.sh/gh/ryz310/projects/redis-objects-periodical)
[![Code Coverage](https://qlty.sh/gh/ryz310/projects/redis-objects-periodical/coverage.svg)](https://qlty.sh/gh/ryz310/projects/redis-objects-periodical)

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

Use Docker with the Compose plugin (`docker compose`). The development image uses
Ruby 2.7 and Bundler 2.3.26, matching the current minimum Ruby version and lockfile.
Agent workflow, compatibility constraints, and validation rules are documented in
[AGENTS.md](AGENTS.md).

The specs connect to the Compose service at `redis:6379` and run `flushdb` after
every example. Use a disposable Redis instance dedicated to this checkout. The
current Compose file publishes host port 6379, which must be available; do not
redirect tests to an existing Redis containing data you want to keep.

Build the development image, start Redis, and install the locked dependencies:

```sh
docker compose build ruby
docker compose up -d redis
docker compose exec redis redis-cli ping
docker compose run --rm ruby bundle install
```

Wait for `redis-cli ping` to return `PONG` before running specs.

```sh
# Run the full suite, or replace the path with an affected spec.
docker compose run --rm ruby bundle exec rspec
docker compose run --rm ruby bundle exec rspec spec/lib/redis/daily_counter_spec.rb

# Check style without automatically modifying source files.
docker compose run --rm ruby bundle exec rubocop

# Build the gem or generate API documentation when relevant.
docker compose run --rm ruby bundle exec rake build
docker compose run --rm ruby bundle exec yardoc
```

Rebuild the image and run `bundle install` again after dependency changes. Stop
the development services with `docker compose down`; routine cleanup does not
require deleting the bundle volume. For parallel checkouts, use distinct Compose
project names and resolve the fixed host-port conflict before starting Redis.

### Continuous integration

GitHub Actions runs on pull requests, pushes to `master` and `release`, and manual
dispatch. The reusable `checks.yml` workflow runs the full specs and builds the
gem on Ruby 2.7, 3.0, 3.1, and 3.2, plus RuboCop on Ruby 2.7. It retains the
existing CircleCI Ruby images and a disposable, job-local `redis` service without
publishing host ports. Bundler 2.3.26 installs the locked dependencies without
dependency caches. `ci.yml` also generates YARD documentation on Ruby 3.2.

SimpleCov generates HTML and JSON coverage reports during specs. Workflow
artifacts are kept for 14 days and include JUnit results, per-Ruby coverage,
built gems, and YARD documentation. Test results and available coverage are saved
even when specs fail. The `upload-coverage` job waits for the reusable checks,
requires all four Ruby result files, and saves the combined
`coverage/coverage.json` as the `merged-coverage` artifact.

To enable coverage reporting to Qlty, enable this repository in Qlty Cloud and
register a dedicated project coverage token as the GitHub Actions repository
secret `QLTY_COVERAGE_TOKEN`. Keep secret variables unavailable to fork and
Dependabot pull requests. When the token is absent, CI still merges and stores
coverage but explicitly skips the upload. When present, the SHA-pinned Qlty
Action publishes the merged report with `skip-errors: false`; upload errors fail
that job. Never commit the token or print its value in logs.

Qlty maintainability analysis and quality gates are configured separately in
Qlty Cloud. Review their results before making new checks required. Coverage
upload alone does not enable or verify those checks.

Third-party and GitHub-owned Actions are pinned to full commit SHAs, with version
comments. Dependabot checks for Actions updates weekly. Routine CI uses read-only
repository permissions and does not persist checkout credentials.

### Release and scheduled maintenance

`release.yml` is prepared for RubyGems Trusted Publishing. It remains disabled
unless the repository variable `GHA_RELEASE_ENABLED` is exactly `true`. Once
enabled, only pushes or manual dispatches on `release` can publish. The workflow
reruns all four Ruby checks and RuboCop against the triggering commit, then
publishes that same commit using Ruby 3.2 and Bundler 2.3.26. YARD and Qlty do not
gate publishing. The publishing job uses fresh dependencies without caches,
checks for an existing version tag or published version, and is not cancelled by
a newer run. Do not run a real release as a migration test.

Before enabling publishing, register this gem's Trusted Publisher on RubyGems.org
with owner `ryz310`, repository `redis-objects-periodical`, workflow filename
`release.yml`, and environment `release`. Create the matching GitHub environment,
restrict it to the `release` branch, and configure its protection rules. The
publishing job alone receives `contents: write` and `id-token: write`; it does not
use `RUBYGEMS_API_KEY`. See the [RubyGems Trusted Publishing guide](https://guides.rubygems.org/trusted-publishing/).

`rubocop_challenge.yml` preserves the daily 08:30 JST schedule. Remote writes
remain disabled unless the repository variable `GHA_CHALLENGE_ENABLED` is exactly
`true`. Manual dispatch on `master` defaults to a read-only dry run using
`--no-create-pr`, which needs neither that variable nor a PR token. Actual PR
creation uses `GITHUB_TOKEN` with job-scoped `contents: write` and
`pull-requests: write`. Enable **Allow GitHub Actions to create and approve pull
requests** in the repository's Actions settings before enabling it. Check the
created PR's CI and approve pending workflow runs if required; PR creation alone
does not prove CI ran. Scheduled workflows run on the default branch, may be
delayed, and can be disabled after 60 days without public repository activity.

### CircleCI migration checklist

The CircleCI configuration and badge have been removed. Repository administrators
must complete the external settings below; removing a file does not update branch
protection, stop already queued jobs, or disable workflows still present on the
old `release` branch. Both `GHA_RELEASE_ENABLED` and `GHA_CHALLENGE_ENABLED` must
stay unset or `false` until the corresponding CircleCI writer is stopped.

1. Verify Actions on a normal PR, a fork PR, and a Dependabot PR. Check all four
   Ruby builds, RuboCop, YARD, JUnit artifacts, and the four-input coverage merge.
   Confirm missing-token skipping and authenticated Qlty reporting separately.
2. Once the Actions checks are available, use their exact reported
   names when updating required checks. Replace only the `ci/circleci:` entries;
   preserve `GitGuardian Security Checks`, strict up-to-date checks, and any
   unrelated protections. Include all four Ruby builds, RuboCop, YARD, and
   `upload-coverage`. Verify a failing test or missing coverage input blocks
   merging before retiring CircleCI checks.
3. Prepare the Trusted Publisher and protected `release` environment. Stop and
   drain CircleCI publishing before setting `GHA_RELEASE_ENABLED=true`. Run the
   first real publish only as an explicitly requested release task; first
   inspect existing tags and RubyGems versions, including any partial release.
4. Run the Challenge dry run. Stop and drain the CircleCI Challenge schedule
   before setting `GHA_CHALLENGE_ENABLED=true`. Check an actual generated PR and
   its CI before considering this step complete.
5. Stop the CircleCI project and confirm no queued or running jobs remain. Remove
   obsolete CircleCI credentials and integration only after confirming they are
   not shared with other projects. Keep the migration commit available for
   restoring the previous configuration if needed.

For rollback, disable the Actions write variables and drain any running jobs
before restoring the corresponding CircleCI writer. Restore previously recorded
required checks together with the previous CircleCI configuration and keep at
least one complete CI path active. Never enable both
publishers or both Challenge writers at once. Do not delete existing release tags
or retry publishing blindly after a partial failure.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/redis-objects-periodical. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/redis-objects-periodical/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Redis::Objects::Daily::Counter project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/redis-objects-periodical/blob/master/CODE_OF_CONDUCT.md).
