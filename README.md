[![CI](https://github.com/ryz310/redis-objects-periodical/actions/workflows/ci.yml/badge.svg)](https://github.com/ryz310/redis-objects-periodical/actions/workflows/ci.yml) [![Gem Version](https://badge.fury.io/rb/redis-objects-periodical.svg)](https://badge.fury.io/rb/redis-objects-periodical)
[![Maintainability](https://qlty.sh/gh/ryz310/projects/redis-objects-periodical/maintainability.svg)](https://qlty.sh/gh/ryz310/projects/redis-objects-periodical)
[![Code Coverage](https://qlty.sh/gh/ryz310/projects/redis-objects-periodical/coverage.svg)](https://qlty.sh/gh/ryz310/projects/redis-objects-periodical)

# Redis::Objects::Periodical

This is a gem which extends [Redis::Objects](https://github.com/nateware/redis-objects) gem. Once install this gem, you can use the periodical counter, the periodical set, etc. in addition to the standard features of Redis::Objects. These counters and sets are useful for measuring conversions, implementing API rate limiting, MAU, DAU, and more.

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
Ruby 3.3 and Bundler 4.0.23, matching the current minimum Ruby version and lockfile.
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
gem on Ruby 3.3, 3.4, and 4.0, plus RuboCop on Ruby 3.3. It retains the
CircleCI Ruby images and a disposable, job-local `redis` service without
publishing host ports. Bundler 4.0.23 installs the locked dependencies without
dependency caches. Git trusts only the current workspace inside the container,
and each build verifies that the gem includes every Ruby source under `lib/`.
`ci.yml` also generates YARD documentation on Ruby 3.3, tests the Dependabot
policy without API writes (`dependabot-policy`), and runs an isolated optional
ActiveSupport integration job on Ruby 3.3 (`active-support-timezone`).

SimpleCov generates HTML and JSON coverage reports during specs. Workflow
artifacts are kept for 14 days and include JUnit results, per-Ruby coverage,
built gems, and YARD documentation. Test results and available coverage are saved
even when specs fail. The `upload-coverage` job waits for the reusable checks,
requires all three Ruby result files, and saves the combined
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

### Optional ActiveSupport integration

The regular suite excludes `spec/integration/**/*_spec.rb` so its plain Ruby
checks do not load ActiveSupport. The separate `active-support-timezone` job runs
on the minimum supported Ruby (currently 3.3), using
`gemfiles/active_support.gemfile` and its own lockfile. ActiveSupport is an
optional integration-test dependency; the gem remains usable without Rails or
ActiveSupport. This job verifies the selected Ruby/ActiveSupport pair; other
Rails releases and Ruby/ActiveSupport combinations are outside its verified scope.

#### ActiveSupport version selection

Select the newest stable ActiveSupport minor series that accepts the gem's
minimum Ruby version and is still covered by upstream security maintenance at
the time of review. Revisit the selection as Ruby requirements and upstream
maintenance change. Check both the
[RubyGems Ruby requirement](https://rubygems.org/gems/activesupport) and the
[Rails maintenance policy](https://rubyonrails.org/maintenance) when selecting
or reviewing the series.

As reviewed on 2026-10-27, the selected series is **ActiveSupport 8.1** with
`gem 'activesupport', '~> 8.1.4'`. Version
[8.1.4 requires Ruby >= 3.2.0](https://rubygems.org/gems/activesupport/versions/8.1.4),
so it can be tested on the Ruby 3.3 baseline. The upstream policy currently lists
security maintenance for 8.1 through 2027-10-10. Regular bug-fix maintenance
follows a separate support window.

The constraint allows `>= 8.1.4, < 8.2`, including later patches/security releases
in 8.1. The separate lockfile pins the exact tested release (currently 8.1.4),
and CI installs that lockfile with `BUNDLE_FROZEN=true`; CI does not resolve a new
version on every run. Raising the patch floor or selecting another minor/major
series requires an explicit dependency change and successful validation.

Review this choice when the Ruby minimum changes, a newer compatible stable
series is released, or the selected series approaches the end of security
maintenance. Update the constraint and optional lockfile together, retain
unrelated baseline dependencies where compatible, and run the isolated timezone
suite, the plain-Ruby suite, RuboCop, and the gem build. Record the reviewed date,
chosen release, and upstream sources in this section; report verification results
in the PR. Compatibility with older ActiveSupport releases remains outside this
job's verified scope. The optional dependency does not change
the gemspec's Ruby requirement or add an ActiveSupport runtime dependency.

#### Timezone verification contract

The integration checks all six periods and four object types against real Redis,
with `Time.zone` set to `Asia/Tokyo` and unset. Timecop freezes UTC at year/month
and Sunday/Monday boundaries, while the process timezone stays UTC. Weekly keys
retain the existing Monday-based `%Y`/`%W` format, including the previous year
when the Monday belongs to December; they are not ISO week-year keys.

The contract is that periodical objects select and persist keys using the real
ActiveSupport `Time.current`/`Time.zone` behavior, with the process clock as the
fallback when `Time.zone` is unset. The job's `TZ=UTC` fixes the process timezone;
the [integration spec](spec/integration/redis/recurring_at_intervals_spec.rb)
uses `Time.use_zone(zone) { example.run }` to set `Asia/Tokyo` or `nil` for each
example. These settings exercise separate layers of timezone selection.

Expected key suffixes are fixed fixture values, independent of `Time.current`
at assertion time. For example, `2020-12-31 23:30 UTC` is
`2021-01-01 08:30` in Tokyo, so annual keys must end in `2020` and `2021`,
respectively. Assertions check the object's key and the corresponding persisted
Redis entry. Comparing the object's time with `Time.current` alone would not
establish that a particular timezone was applied.

The current inventory is two boundary instants x two zone settings x six periods
x four object types: **96 examples, with 48 per zone setting**. This covers the
selected Tokyo/unset cases and year/month/week boundaries; other zones and DST
transitions remain outside this suite's verified scope.

#### Recorded execution evidence and open gap

On 2026-10-27, the JUnit artifact from the
[successful CI run for commit 8ab4de1](https://github.com/ryz310/redis-objects-periodical/actions/runs/40409599457)
confirmed both zone groups actually ran under Ruby 3.3 / ActiveSupport 8.1.4.
A separate diagnostic changed `Time.use_zone(zone)` to `Time.use_zone(nil)` in
an isolated temporary copy and ran it against disposable Redis:

| Verification | Tokyo: executed / failed | Unset: executed / failed |
| --- | --- | --- |
| Actual CI JUnit report | 48 / 0 | 48 / 0 |
| Temporary copy with the zone setting disabled | 48 / 36 | 48 / 0 |

Both reports contained zero errors and zero skipped examples. The diagnostic
failed on incorrect keys, for example expected annual suffix `2021` versus actual
`2020`. Some periods share a key at one of the two boundary instants, so disabling
the zone does not make every Tokyo example fail. This experiment confirms that
the assertions detect ineffective timezone selection; it is a recorded one-off
diagnostic, not an additional CI step.

**Open verification gap:** the [workflow](.github/workflows/ci.yml) runs the
explicit spec file and overrides the default exclusion, but it does not validate
the per-zone execution inventory in the JUnit report. The evidence above confirms
this particular run included both groups. A future filter or removal could leave
only the unset group running and passing without an explicit missing-group error.

Follow-up work is to fail CI when either intended zone group is absent or empty,
or intended examples are skipped, using explicit group execution and/or JUnit
validation. Keep that
inventory check aligned with deliberate changes to the fixtures. This guard is
not implemented by the current workflow.

Run it separately with the same disposable Compose Redis as the regular suite:

```sh
docker compose run --rm -e BUNDLE_GEMFILE=gemfiles/active_support.gemfile ruby bundle install
docker compose run --rm -e TZ=UTC -e BUNDLE_GEMFILE=gemfiles/active_support.gemfile ruby bundle exec rspec spec/integration/redis/recurring_at_intervals_spec.rb --exclude-pattern ''
```

The empty `--exclude-pattern` overrides `.rspec` for this explicit integration
run. The normal three-Ruby coverage merge remains unchanged; the separate job
stores its own JUnit and coverage artifacts.

### Dependency updates and auto-merge

Dependabot checks Bundler and GitHub Actions weekly on Monday at 08:00 JST.
Bundler version updates wait 3 days for patches, 7 for minor updates, and 14 for
major updates (7 days by default). Actions updates use a 7-day default cooldown;
SemVer-specific cooldown settings are not applied to that ecosystem. These
cooldowns apply to version updates, not security updates.

`dependabot-auto-merge.yml` can reserve auto-merge for a narrow set of updates:

- Bundler patch/minor updates of `pry-byebug`, `rake`, `rspec`,
  `rspec_junit_formatter`, `rubocop`, `rubocop-performance`, `rubocop-rspec`,
  `simplecov`, `timecop`, and `yard`, changing only `Gemfile.lock`. The locked
  runtime dependency entries (`redis-objects-periodical`, `redis-objects`,
  `redis`, `redis-client`, and `connection_pool`) must stay identical. Only gem
  spec/version and transitive dependency requirement lines may change.
- SHA-pinned patch/minor replacements for `actions/checkout`,
  `actions/upload-artifact`, `actions/download-artifact`, and
  `actions/github-script`, changing only `uses:` lines and their version comments
  in existing workflow files.

Every named dependency in a grouped update must be permitted. Major updates,
Bundler itself, runtime dependencies, optional integration lockfiles, manifest
constraints, source/platform changes, third-party Actions, and workflow
permission/trigger/step changes require manual review. Unknown metadata, missing
or incomplete patches, a changed PR head, forks, and API errors do not enable
merging. The merge command also matches the exact inspected head commit.

The privileged workflow uses `pull_request_target` only to obtain the write
permissions unavailable on normal Dependabot PR events. It checks out only the
trusted base commit's `.github/scripts` policy with credentials disabled, never
executes PR code, and inspects changes through the GitHub API. Its trigger has a
scoped zizmor exception for this metadata-only design. Policy regressions run in
ordinary read-only CI:

```sh
node --test .github/scripts/dependabot-policy.test.cjs
```

Repository administrators must finish these settings after the new checks have
appeared on a PR:

1. Enable repository auto-merge with merge commits and preserve existing required
   reviews, security checks, and other protections.
2. On `master`, require status checks and require the branch to be up to date.
   Keep all three `checks / build_on_ruby_*` checks, `checks / rubocop`, `yardoc`,
   and `upload-coverage`; add `active-support-timezone` and `dependabot-policy`.
3. Set repository variable `GHA_DEPENDABOT_AUTOMERGE_ENABLED=true` only after
   confirming those settings. Until then, the auto-merge job skips all writes.
4. Verify on an eligible Dependabot PR that a failing required check prevents
   merging and that an excluded update stays manual. Re-run the metadata workflow
   for existing PRs after setup, or let their next update trigger it.

The policy verifies the repository's auto-merge setting and the effective
rulesets plus any classic branch protection, including all eight named checks and
strict up-to-date checks, before reserving a merge. Preserve GitGuardian and all
other existing required checks. If protection cannot be read or is missing, it
leaves the PR for manual review. Merge queues are not supported by this workflow. No branch-protection, repository-variable, or
publication setting is changed by the workflow. Disable the enable variable to
stop new reservations; disable auto-merge on already-reserved PRs separately if
rolling back.

### Release and scheduled maintenance

`release.yml` is prepared for RubyGems Trusted Publishing. It remains disabled
unless the repository variable `GHA_RELEASE_ENABLED` is exactly `true`. Once
enabled, only pushes or manual dispatches on `release` can publish. The workflow
reruns all three Ruby checks and RuboCop against the triggering commit, then
publishes that same commit using Ruby 3.3 and Bundler 4.0.23. YARD and Qlty do not
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
`--no-create-pr`. The CLI requires a token even for a dry run, so that job uses
the automatic read-only `GITHUB_TOKEN` and does not need the enable variable.
Actual PR creation uses `GITHUB_TOKEN` with job-scoped `contents: write` and
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

1. Verify Actions on a normal PR, a fork PR, and a Dependabot PR. Check all three
   Ruby builds, RuboCop, YARD, JUnit artifacts, and the three-input coverage merge.
   Confirm missing-token skipping and authenticated Qlty reporting separately.
2. Once the Actions checks are available, use their exact reported
   names when updating required checks. Replace only the `ci/circleci:` entries;
   preserve `GitGuardian Security Checks`, strict up-to-date checks, and any
   unrelated protections. Include all three Ruby builds, RuboCop, YARD, and
   `upload-coverage`. Verify a failing test or missing coverage input blocks
   merging before retiring CircleCI checks.

   For the Ruby support update, also replace required checks for Ruby 2.7, 3.0,
   3.1, and 3.2 with the reported checks for Ruby 3.3, 3.4, and 4.0. Keep RuboCop,
   YARD, coverage, and unrelated protections required. Update protection only
   after the new checks have run successfully.
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
