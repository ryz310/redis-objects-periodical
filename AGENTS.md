# AGENTS.md

## Project and sources of truth

- This Ruby gem extends `redis-objects` with counters, values, sets, and hashes
  for six intervals: annual, monthly, weekly, daily, hourly, and minutely.
- Read [README.md](README.md) for public usage and development commands. Check
  implementation and specs before changing behavior.
- When a repository's documentation and its existing code disagree, follow the
  conventions used in the existing code, and in your final reply point out each
  inconsistency you found between the documentation and the code.
- Apply this default to descriptions of existing conventions. It does not
  override explicit user requests, security or compatibility requirements,
  configured test/lint checks, or an approved migration. If existing behavior
  appears defective or intent is unclear, surface the decision rather than
  treating the code as correct by definition.
- Report inconsistencies encountered during the task with relevant file
  references; this does not require a repository-wide audit. The precedence
  sentence comes from [Xu and Wu (2026), section 4](https://arxiv.org/html/2610.30571v1#S4);
  the scope and exceptions above are this repository's adaptation.
- Entry point and generated classes: `lib/redis-objects-periodical.rb`,
  `lib/redis/periodical_*.rb`, and `lib/redis/objects/periodical_*.rb`.
- Shared date/range behavior: `lib/redis/recurring_at_intervals.rb`; key formats
  and interval arithmetic: `lib/redis/recurring_at_intervals/`.
- Type-specific reads, aggregation, and deletion: `lib/redis/base_*_object.rb`.
- Behavior specs: `spec/lib/redis/`; Redis connection and cleanup:
  [spec/spec_helper.rb](spec/spec_helper.rb).
- Dependencies and packaging: [Gemfile](Gemfile),
  [redis-objects-periodical.gemspec](redis-objects-periodical.gemspec), and
  [Gemfile.lock](Gemfile.lock). CI lives in
  [.circleci/config.yml](.circleci/config.yml), not GitHub Actions.

## Task workflow

- Check the checkout, branch, `git status`, and `git worktree list` first.
  Preserve unrelated work and keep the task focused.
- Start independent work from an up-to-date `master`: fetch `origin`, update
  with a fast-forward only, re-read this file, and create `codex/<task-name>`
  (`claude/<task-name>` for Claude Code). Continue an existing task on its branch.
  Do not reset local changes or force a divergent branch to match the remote.
- Explain scope and verification before substantial changes. Keep unrelated
  cleanup, dependency upgrades, and support-policy changes separate.
- At completion, report changes, verification results, and unverified items.
  Propose a brief KPT retrospective when useful; keep it in the conversation
  unless the user requests another destination. Propose durable guidance changes
  based on findings rather than expanding this file for one-off workarounds.

## Runtime and compatibility

- Preserve the repository's declared Ruby minimum of 2.7 (`required_ruby_version`)
  and `redis-objects ~> 1.0` dependency unless changing support is in scope.
  The Docker development baseline and RuboCop target are Ruby 2.7; the configured
  CircleCI build matrix covers Ruby 2.7, 3.0, 3.1, and 3.2. These describe this
  repository's configuration, not upstream maintenance status.
- This is a standalone gem. Rails/ActiveSupport is optional; preserve both
  `Time.current` and plain Ruby `Time.now` behavior without adding a Rails runtime
  dependency for convenience.
- A support-policy change must align the gemspec, Dockerfile, Gemfile/lockfile,
  RuboCop target, CircleCI matrix/coverage aggregation, README, and this guide.
  Keep the Dockerfile's Bundler version compatible with Ruby and aligned with
  the lockfile's `BUNDLED WITH` version.
  Validate specs, lint, and gem build even if no `.rb` file changes.

## Redis and development environment

- Use the Compose `ruby` service for development and the `redis` service for
  tests. Follow the setup and commands in [README.md](README.md#development).
- Specs use real Redis at the hard-coded `redis:6379` address and call `flushdb`
  after every example. Use only the disposable Redis belonging to this checkout;
  never point that hostname at shared or production data. Do not assume setting
  `REDIS_URL` redirects this test suite.
- Compose currently publishes host port 6379. If it is occupied, report the
  conflict; do not stop another project's Redis. For parallel checkouts, use
  distinct Compose project names and explicitly resolve host-port conflicts;
  a project name alone does not isolate the published port.
- Use `bundle exec` for project tools. After dependency changes, rebuild the
  image and run `bundle install` in the mounted service so the bundle volume
  matches the lockfile. Avoid an unrelated `bundle update`.
- Prefer `docker compose down` for cleanup. Volume deletion is unnecessary for
  routine development. Do not invoke `rake release` as a validation command.

## Validation and code review

- For behavior changes, run focused specs first, then the full suite against
  disposable Redis. Add regression coverage for the changed contract.
- For shared interval/type changes, check affected combinations across all six
  periods and four object types. Preserve persisted key formats, week/year
  boundaries, time-zone selection, expiration options, range boundaries,
  missing/empty values, aggregation, and standard `Redis::Objects` behavior
  unless the requested change explicitly alters them.
- Freeze or travel time with Timecop in specs; test boundaries deterministically
  rather than sleeping. Existing cleanup restores Timecop after each example.
- Run RuboCop for Ruby, gemspec, Gemfile, Rakefile, or lint configuration changes.
  Use configured cops as the style authority; avoid mass autocorrection or
  regenerating `.rubocop_todo.yml` to conceal new offenses.
- Run `bundle exec rake build` through Compose for packaging/dependency changes;
  use `bundle exec yardoc` for documentation-comment changes. The gemspec packages
  Git-tracked files, so check the tracked file list when adding packaged sources.
- For Markdown-only changes, check paths, commands, examples, and
  `git diff --check`; application specs/lint are unnecessary unless the task also
  requires validating the documented runtime procedure.
- If validation is blocked, state the command and reason. Do not present static
  checks or one local Ruby run as a successful CircleCI compatibility matrix.

## Documentation, pull requests, and releases

- Keep user-facing documentation in the English `README.md`; do not create
  language-specific README copies. Keep agent workflow in this file.
- When updating examples, check method names, arguments, key formats, return
  values, and consistency with specs. Resolve references when renaming/removing
  documentation.
- Write PR titles and descriptions in English. Include `Purpose of this change`
  and relevant verification results. Supply Markdown bodies through structured
  tool arguments or a temporary file with `gh --body-file` to avoid shell
  interpretation of backticks and other Markdown content.
- Compile `CHANGELOG.md` at release time rather than editing it in every PR.
  Follow existing release formatting and `-` bullets; categorize entries as
  Feature, Bugfix, Security, Breaking Change, Rubocop Challenge, Dependabot, or
  Misc as applicable, omitting empty sections. Reserve Breaking Change for
  backward-incompatible behavior and combine repeated dependency bumps.
- Releases require an explicit release task. CircleCI publishes from the
  `release` branch; pushing there or running `rake release` is not routine
  development. Keep version changes, tags, and publishing within that scope.
