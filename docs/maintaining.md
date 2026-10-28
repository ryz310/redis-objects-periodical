# Maintaining

See [Contributing](../CONTRIBUTING.md) for development and test commands.
Keep unresolved work in [GitHub Issues](https://github.com/ryz310/redis-objects-periodical/issues).
This guide describes procedures; it does not certify that external settings or
CircleCI cutover have been completed.

## Coverage reporting

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

## Dependency updates and auto-merge

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
merging. The enable mutation also requires the exact inspected head commit.
If GitHub rejects enabling auto-merge specifically because the PR is already in
clean status, the workflow repeats policy and protection verification and checks
the current head, base, open/clean state, and absence of a reservation before
merging with an exact-head guard. Other enable errors fail the workflow.

The privileged workflow uses `pull_request_target` only to obtain the write
permissions unavailable on normal Dependabot PR events. It checks out only the
trusted base commit's `.github/scripts` policy with credentials disabled, never
executes PR code, and inspects changes through the GitHub API. Its trigger has a
scoped zizmor exception for this metadata-only design. Policy regressions run in
ordinary read-only CI:

```sh
node --test .github/scripts/*.test.cjs
```

Repository administrators must finish these settings after the new checks have
appeared on a PR:

1. Enable repository auto-merge with merge commits and preserve existing required
   reviews, security checks, and other protections.
2. On `master`, require status checks and require the branch to be up to date.
   Keep all three `checks / build_on_ruby_*` checks, `checks / rubocop`, `yardoc`,
   and `upload-coverage`; add `active-support-timezone` and `dependabot-policy`.
3. Verify on an eligible Dependabot PR that a failing required check prevents
   merging and that an excluded update stays manual. For existing PRs, let their
   next update trigger the workflow.

Matching Dependabot PR events run the workflow without a separate enable
variable. The policy below verifies the repository settings before allowing a
merge.

The policy verifies the repository's auto-merge setting and the effective
rulesets plus any classic branch protection, including all eight named checks and
strict up-to-date checks, before reserving a merge. Preserve GitGuardian and all
other existing required checks. If protection cannot be read or is missing, it
rejects the update. On a current-head rejection or verification error (including
metadata-fetch failure), the workflow revokes an earlier reservation only when
its ownership can be verified. The reservation's merge commit body contains a
small policy marker identifying the repository, PR, inspected head, and workflow
run. Ownership requires both the GitHub Actions bot and a matching originating
workflow run; this marker remains in the eventual merge commit body. Human,
unrelated automation, and legacy unmarked reservations are preserved with a
manual-inspection notice. Failure to read ownership or confirm cancellation
fails the workflow and requires manual inspection of the PR's auto-merge state.

Runs for one PR are serialized, stale events do not change the current head's
reservation, and cancellation rechecks the head and reservation immediately
before writing and verifies the result afterward. GitHub's disable mutation has
no conditional head/reservation argument, so administrators and other automation
must avoid changing reservations concurrently with this workflow. A concurrent
external write between the final read and cancellation cannot be guarded
atomically by this API.

Merge queues are not supported. No branch-protection, repository-variable, or
publication setting is changed by the workflow. When rolling back,
[disable the Dependabot Auto Merge workflow](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows)
to prevent new runs, cancel any active runs, and disable auto-merge on
already-reserved PRs separately. Disabling the workflow does not cancel active
runs or revoke existing reservations. Also inspect reservations manually if the
job is skipped (for example after retargeting away from `master`), checkout fails,
a run is cancelled or times out, or an
ownership marker's originating run is no longer available. Only the configured
PR events trigger re-evaluation; settings changes do not trigger it.

## Release and scheduled maintenance

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

## CircleCI migration checklist

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
