---
name: gem-release
description: Prepare, review, or resume a redis-objects-periodical gem release using the gem_comet CLI. Leave Update and Release PRs unmerged unless the user explicitly authorizes their merges; finish an explicitly authorized publication with a GitHub Release draft. Ordinary dependency maintenance is outside this skill.
---

# Gem release

Operate on `ryz310/redis-objects-periodical`. Creating, editing, or explaining
this skill does not execute a release.

## Sources and scope

Read the current versions of:

- [AGENTS.md](../../../AGENTS.md): workflow, compatibility, and CHANGELOG rules.
- [CONTRIBUTING.md](../../../CONTRIBUTING.md): isolated Compose and validation.
- [Maintaining](../../../docs/maintaining.md#release-and-scheduled-maintenance)
  and its [migration checklist](../../../docs/maintaining.md#circleci-migration-checklist):
  publishing prerequisites, external cutover, and rollback.
- [.gem_comet.yml](../../../.gem_comet.yml),
  [release.yml](../../../.github/workflows/release.yml), and
  [checks.yml](../../../.github/workflows/checks.yml): actual branches, paths,
  release gates, and checks.
- [Gemspec](../../../redis-objects-periodical.gemspec), root and optional
  ActiveSupport manifests/lockfiles, and the installed release tool's code.

Derive versions, supported Rubies, checks, and paths from these sources rather
than copying a previous release's values. `.gem_comet.yml`'s `version` is a
configuration schema version, not the gem or installed tool version.

Prepare `Update vVERSION` and `Release vVERSION` PRs for review and leave both
unmerged, without auto-merge or merge-queue enrollment. Requests such as "use
the skill to release", "start the release", or "resume" do not authorize either
PR's merge. Passing CI, CHANGELOG approval, and confirmation of credentials or
publisher setup do not supply that authorization either.

Merge only after a direct user instruction explicitly covers the relevant PR
or merge stage. Approval to merge the Update PR does not authorize merging the
Release PR. A single explicit instruction covering both stages is sufficient;
reuse that authorization without asking again unless its scope changes. Do not
use a workflow dispatch or local publishing command to bypass the merge gate.

Merging the Release PR into the configured publication branch can publish a gem.
After that explicitly authorized publication, finish with an unpublished GitHub
Release draft. Publishing the draft is a separate action. Return unresolved
version, compatibility, migration, or external configuration decisions to the
user. Creating a skill or merging Dependabot updates does not authorize release
PR merges or gem publication.

## Immediate credential gate

Before release execution or resumption, use minimal read-only inspection to
identify the selected authentication path, then follow the
[credential gate](references/execution-and-recovery.md#credential-gate).
Verify the required authentication in the intended tool/process environment
before branch changes, installation, edits, artifact generation, or mutations.
If it is missing, invalid, inaccessible, or unverifiable, stop release execution
immediately. Report the mechanism and configuration location, never its value;
ask for configuration outside chat, not disclosure of a secret.

An offline review needs no unrelated credentials. Skill authoring does not run
this gate. Trusted Publishing does not require a local RubyGems API key, and
future OIDC token issuance is not a missing local secret. Check only the
prerequisites needed for the requested scope.

## Establish or resume the release

1. Confirm repository identity, checkout, branch, status, worktrees, remote SHAs,
   existing update/release PRs, tags, RubyGems versions, and publication runs.
   Do not display credential-bearing remotes or environment dumps.
2. Identify completed stages before changing branches. Reuse existing PRs and
   preserve user work. For fresh preparation, follow AGENTS.md's current-master,
   fast-forward-only rule and use a new `codex/` topic branch. The configured
   `release` branch remains the publication target.
3. Establish the previous actual published version using RubyGems metadata,
   tags, and GitHub evidence. Inspect the full reachable change set and PRs,
   including squash merges; tag dates and merge-message parsing alone are
   insufficient. Distinguish runtime changes, development dependencies, Actions,
   documentation, and verification-only changes.
4. Explain the proposed version and compatibility impact. Check persisted Redis
   keys, week/year and timezone boundaries, range semantics, missing values,
   aggregation, expiration, Ruby requirements, and upstream Redis::Objects
   compatibility. A bug fix that changes access to existing keys still needs
   an explicit migration assessment. Do not invent migration behavior or assume
   a version from an earlier chat has been approved.

## Prepare reviewable PRs

Read [execution and recovery](references/execution-and-recovery.md) before
setting up tools or making external changes. Inspect installed gem_comet and
pr_comet behavior, then use the actual `gem_comet changelog` and
`gem_comet release VERSION` CLI commands. Calling `GemComet::Release.call` or
other internal Ruby services is not a substitute for CLI execution. Do not
monkey-patch the tool's release stages or generator to simulate that execution.
An unrestricted dependency update is not implied by release preparation. If
the supported CLI/configuration cannot satisfy the requested constraints,
explain the limitation and obtain the user's decision before mutation rather
than silently replacing the CLI. Follow the
[CLI and generation-history procedure](references/execution-and-recovery.md#cli-and-generation-history).

- Update the configured version source and the path-gem entry in **both**
  tracked lockfiles, currently `Gemfile.lock` and
  `gemfiles/active_support/Gemfile.lock`. Read their individual old versions.
  Preserve unrelated versions, constraints, platforms, and Bundler settings.
  Keep ActiveSupport optional and outside runtime dependencies.
- Compile CHANGELOG only for this release, using AGENTS.md and the configured
  categories/order. Preserve the CLI-generated CHANGELOG commit unchanged, then
  make editorial corrections in a separate follow-up commit. Do not substitute
  pre-edited text before the tool's first commit or amend/squash that evidence.
  Omit empty categories, use `-` bullets, explain backward-incompatible behavior,
  and supplement missing squash merges or migration notes. Preserve previous
  release entries.
- For repeated Dependabot updates to the same dependency, retain only its final
  update PR. Use that PR's old/new versions and established contributor
  attribution, in the form `- [#N](URL) Bump name from OLD to NEW ([@user](URL))`.
  Do not enumerate intermediate PRs or replace OLD with the version at the start
  of the entire release interval. If a grouped PR title omits versions, verify
  them in its body/diff. Keep consecutive bullet items together with no blank
  lines between them; retain a blank line after the heading and before the next
  category.
- Use English PR titles/bodies with `Purpose of this change`. Explain version
  choice, compatibility/migrations, dependency scope, checks, and merge order:
  update PR into `master`, then `master` into `release`, as configured.
- Preserve generated TODO items, checkbox states, attribution, and human edits
  using the [PR content procedure](references/execution-and-recovery.md#preserve-pr-content).
  Mark only `Edit the CHANGELOG.md` complete after its reviewed content is in
  the current update PR diff; do not mark other decisions complete implicitly.
- Use structured bodies or temporary files with `--body-file`. Attach every
  created PR to the current chat when the app tool is available.

## Validate preparation

Use CONTRIBUTING.md's Compose commands and a unique `COMPOSE_PROJECT_NAME` for
this checkout. Specs use real Redis at `redis:6379` and flush it after each
example; use only this project's disposable service. Verify both bundles with
frozen installs after synchronizing the lockfiles.

Run the required specs, RuboCop, and gem build for release changes, including a
version-only Ruby edit. Use CI evidence on the exact final head for the supported
Ruby matrix and optional ActiveSupport timezone/inventory checks; one local Ruby
run is not matrix verification. Validate workflow changes with actionlint and
zizmor if such changes are actually in scope.

Inspect package contents: the gemspec uses `git ls-files`, so new runtime files
must be tracked. Confirm all runtime sources, the intended version and Ruby
requirement, and runtime dependency constraints. The current gemspec includes
tracked `.agents/` files; do not claim they are excluded or silently change
packaging policy during a release. Report unexpected package contents.

Review the final diff and whitespace, both lockfiles, exact head checks, and
remaining findings. Distinguish successful coverage collation from an actual
Qlty upload. Report the actual CLI commands/tool versions, generated CHANGELOG
commit, editorial follow-up commits, PR URLs, and validation. Do not describe
an internal API invocation as standard CLI execution. Without explicit merge
instructions, end with both PRs unmerged and a concrete review handoff.

## Merge and publish within authorization

1. Confirm a direct user instruction authorizes the Update PR's merge. If none
   exists, leave it open and report readiness. With authorization, recheck its
   head, diff, reviews, base, and required checks; merge with an expected-head
   guard and verify master integration. Do not infer Release PR merge approval
   from this stage's approval or successful integration.
2. Verify the release PR includes the intended version/CHANGELOG and current
   release workflow. Recheck its updated head and CI after the update PR merges;
   inspect the full delta against the publication branch, including any old
   CircleCI configuration. Never bypass protection. Without a direct instruction
   authorizing this Release PR's merge, leave it open even when all checks pass.
3. Before publication, verify `GHA_RELEASE_ENABLED=true`, the matching protected
   `release` environment and RubyGems Trusted Publisher, and that the old
   CircleCI publisher is stopped and drained. Follow the migration checklist;
   do not infer cutover from removed configuration. Missing or unverifiable
   prerequisites block publication, not offline assessment. Do not enable
   variables, edit protection, or revive a publisher outside authorized scope.
4. With explicit authorization to merge the Release PR, recheck that the
   instruction still covers its current contents, then merge its exact inspected
   head. Observe the resulting run. Do not also dispatch a duplicate run or invoke
   local `rake release`. A skipped publishing job is not a successful release.
5. Verify the workflow, tag's peeled commit SHA, RubyGems metadata and checksum,
   and downloaded package contents against the intended tested commit. Inspect
   partial state before retrying; never automatically move tags, yank a version,
   or republish an existing version.
6. Create or reuse the [final GitHub Release draft](references/execution-and-recovery.md#final-github-release-draft)
   from the verified tag's CHANGELOG. Read back its tag, title/body, prerelease
   setting, and draft state. Leave it unpublished.

Report the PRs, version, tested/published commit, tag, gem and draft URLs,
verification, and incomplete stages. State documentation/code inconsistencies
encountered and offer a brief KPT when useful. Propose reusable guidance fixes
instead of adding one-off rules to AGENTS.md.

Adapted from [my_api_client's gem-release skill](https://github.com/ryz310/my_api_client/tree/master/.agents/skills/gem-release).
