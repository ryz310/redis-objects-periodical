# Contributing

Report bugs and propose improvements through
[GitHub Issues](https://github.com/ryz310/redis-objects-periodical/issues), with a
reproduction and expected behavior where possible. Link implementation PRs to
their issues and include verification results. Follow the
[code of conduct](CODE_OF_CONDUCT.md).

## Development

Use Docker with the Compose plugin (`docker compose`). The development image uses
Ruby 3.3 and Bundler 4.0.23, matching the current minimum Ruby version and lockfile.
Agent workflow, compatibility constraints, and validation rules are documented in
[AGENTS.md](AGENTS.md).

The specs connect to the Compose service at `redis:6379` and run `flushdb` after
every example. Use a disposable Redis instance dedicated to this checkout. The
Redis service is accessible only inside its Compose network; no host port is
published. Do not redirect tests to an existing Redis containing data you want
to keep.

Development Redis uses
`redis:latest@sha256:97ec88159e6d7cfb5ddef9015386087d58a912de80112f06ebdfa78fa5989901`,
the same immutable image digest as the Redis services in
[checks.yml](.github/workflows/checks.yml) and [ci.yml](.github/workflows/ci.yml).
The digest fixes the image contents even if the `latest` tag moves.

To update Redis, review the intended server version and release notes, then
update the image reference in `docker-compose.yml`, both CI workflows, and this
paragraph together. Pull the selected image with `docker compose pull redis`,
recreate the disposable service with `docker compose up -d redis`, and run the
full specs below. Validate workflow edits with actionlint and zizmor, and check
the Ruby matrix and optional ActiveSupport job in CI before merging.

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
require deleting the bundle volume.

For parallel checkouts, choose a distinct Compose project name in each checkout's
shell before running any of the commands above:

```sh
# Use a different name in each checkout, for example rop-feature-b in the second.
export COMPOSE_PROJECT_NAME=rop-feature-a
```

Keep that name for every Compose command in the same checkout, including
`docker compose down`. Compose then creates separate Redis services, networks,
and bundle volumes for each project. Do not give those resources a shared name
or attach another project's Redis to the test network. Run specs inside the
`ruby` service so the internal `redis:6379` endpoint resolves to that project's
disposable Redis. For an interactive Redis client, use
`docker compose exec redis redis-cli`; host-port publishing is unnecessary.

## Continuous integration

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

Both lockfiles select redis-objects 2.0.0. The regular suite therefore includes
96 key-prefix examples: legacy/modern x six periods x four types x instance/global
fields. They check literal expected keys and persisted Redis entries, using a
fresh namespaced model per example and restoring the global prefix style afterward.
These examples run unconditionally in the locked 2.0.0 CI environment, so a
missing `prefix_style` API fails the suite instead of silently excluding coverage.
The migration suite additionally covers all period/type/global combinations,
payload and TTL preservation, collisions and retries, cached prefixes, and field
connections. Both suites require the 2.x API. The gemspec still permits 1.x;
when checking a separately prepared 1.x bundle, exclude these two specs:

```sh
docker compose run --rm ruby bundle exec rspec spec/lib/redis \
  --exclude-pattern 'spec/lib/redis/objects_{prefix_style,migrate_redis_legacy_keys}_spec.rb'
```

SimpleCov generates HTML and JSON coverage reports during specs. Workflow
artifacts are kept for 14 days and include JUnit results, per-Ruby coverage,
built gems, and YARD documentation. Test results and available coverage are saved
even when specs fail. The `upload-coverage` job waits for the reusable checks,
requires all three Ruby result files, and saves the combined
`coverage/coverage.json` as the `merged-coverage` artifact.

Coverage credentials and quality-gate administration are described in
[Maintaining](docs/maintaining.md#coverage-reporting).

Third-party and GitHub-owned Actions are pinned to full commit SHAs, with version
comments. Dependabot checks for Actions updates weekly. Routine CI uses read-only
repository permissions and does not persist checkout credentials.

## Optional ActiveSupport integration

The regular suite excludes `spec/integration/**/*_spec.rb` so its plain Ruby
checks do not load ActiveSupport. The separate `active-support-timezone` job runs
on the minimum supported Ruby (currently 3.3), using
`gemfiles/active_support/Gemfile` and its own `Gemfile.lock`. ActiveSupport is an
optional integration-test dependency; the gem remains usable without Rails or
ActiveSupport. This job verifies the selected Ruby/ActiveSupport pair; other
Rails releases and Ruby/ActiveSupport combinations are outside its verified scope.

### ActiveSupport version selection

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

### Timezone verification contract

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

### Execution inventory guard

The [workflow](.github/workflows/ci.yml) also emits an RSpec JSON report and runs
an [execution inventory guard](.github/scripts/timezone-inventory.cjs). The guard
requires every expected boundary/zone/period/type combination exactly once, with
status `passed`. Missing groups or individual combinations, empty selections,
pending/skipped examples, duplicates, and unexpected examples fail the job.
The expected dimensions have one definition in the guard; update it alongside
intentional changes to the integration fixtures. Its regression tests include
missing Tokyo/unset groups and rejected empty/pending reports. The dated
record linked below remains evidence for its recorded commit; this check enforces
the inventory on subsequent runs.

Run it separately with the same disposable Compose Redis as the regular suite:

```sh
docker compose run --rm -e BUNDLE_GEMFILE=gemfiles/active_support/Gemfile ruby bundle install
docker compose run --rm -e TZ=UTC -e BUNDLE_GEMFILE=gemfiles/active_support/Gemfile ruby bundle exec rspec spec/integration/redis/recurring_at_intervals_spec.rb --exclude-pattern ''
```

The empty `--exclude-pattern` overrides `.rspec` for this explicit integration
run. The normal three-Ruby coverage merge remains unchanged; the separate job
stores its own JUnit and coverage artifacts.

The [dated timezone verification record](docs/verification/2026-10-27-timezone.md)
preserves the earlier run and one-off diagnostic; it is not a new test result.

Repository administration and release procedures live in [Maintaining](docs/maintaining.md).
