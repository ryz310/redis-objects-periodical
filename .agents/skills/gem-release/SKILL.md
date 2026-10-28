---
name: gem-release
description: Prepare, review, resume, or publish a redis-objects-periodical gem release using gem_comet and the configured release workflow, ending a full release with a GitHub Release draft. Use for this repository's releases; ordinary dependency maintenance is outside this skill.
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

Determine whether the request authorizes preparation, merging, or publication.
Starting a release normally prepares update and release PRs for review, leaving
both unmerged and without auto-merge. Merging into the configured publication
branch can publish a gem. A full authorized release ends with an unpublished
GitHub Release draft; publishing that draft is a separate action.

Reuse existing authorization. This skill adds no blanket approval requirement.
Return unresolved version, compatibility, migration, or external configuration
decisions to the user. Creating a skill, researching changes, or merging
Dependabot updates does not authorize gem publication.

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
pr_comet behavior before running `gem_comet changelog` or
`gem_comet release VERSION`; do not discover prerequisites through a full run.
An unrestricted dependency update is not implied by release preparation.

- Update the configured version source and the path-gem entry in **both**
  tracked lockfiles, currently `Gemfile.lock` and
  `gemfiles/active_support/Gemfile.lock`. Read their individual old versions.
  Preserve unrelated versions, constraints, platforms, and Bundler settings.
  Keep ActiveSupport optional and outside runtime dependencies.
- Compile CHANGELOG only for this release, using AGENTS.md and the configured
  categories/order. Omit empty categories, use `-` bullets, combine repeated
  dependency bumps, retain PR links, and explain backward-incompatible behavior.
  Supplement generated output when squash merges or compatibility notes are
  missing. Preserve previous release entries.
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
Qlty upload. Preparation-only work ends with PR URLs and verification results.

## Merge and publish within authorization

1. Recheck the update PR's head, diff, reviews, base, and required checks. Merge
   with the inspected head as a guard, then verify master integration.
2. Verify the release PR includes the intended version/CHANGELOG and current
   release workflow. Recheck its updated head and CI after the update PR merges;
   inspect the full delta against the publication branch, including any old
   CircleCI configuration. Never bypass protection.
3. Before publication, verify `GHA_RELEASE_ENABLED=true`, the matching protected
   `release` environment and RubyGems Trusted Publisher, and that the old
   CircleCI publisher is stopped and drained. Follow the migration checklist;
   do not infer cutover from removed configuration. Missing or unverifiable
   prerequisites block publication, not offline assessment. Do not enable
   variables, edit protection, or revive a publisher outside authorized scope.
4. Merge the exact inspected release PR head only when publication is authorized.
   Observe the resulting run. Do not also dispatch a duplicate run or invoke
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
