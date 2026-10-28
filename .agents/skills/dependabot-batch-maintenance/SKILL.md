---
name: dependabot-batch-maintenance
description: Review Dependabot pull requests in this repository and merge an authorized batch one at a time, preserving exclusions and checking compatibility, refreshed branches, current-head CI, and integration results. Use for review-only requests without performing mutations.
---

# Dependabot batch maintenance

## Scope and authorization

- Establish the user's targets, exclusions, and holds before starting.
- For review-only requests, do not post comments, update branches, or merge.
- When batch merging is authorized, continue through eligible PRs without asking
  for confirmation for each PR.
- Preserve an excluded update even if Dependabot recreates it under a new PR
  number. Match exclusions by dependency and update, not only by PR number.
- Releases, support-policy changes, and GitHub protection changes are outside
  this workflow unless separately authorized.

## Repository sources

Read the current versions of these sources at the start:

- [AGENTS.md](../../../AGENTS.md): checkout, compatibility, and validation rules.
- [CONTRIBUTING.md](../../../CONTRIBUTING.md): development and verification commands.
- [Maintaining](../../../docs/maintaining.md#dependency-updates-and-auto-merge):
  dependency update and auto-merge procedures.
- [Workflows](../../../.github/workflows/) and
  [Dependabot policy](../../../.github/scripts/dependabot-policy.cjs): actual
  check configuration and automated merge eligibility.
- Current GitHub branch protection, effective rulesets, and required checks.

Do not hard-code check names, supported Ruby versions, dependency versions, or
PR numbers in this skill. Derive them from the current sources above.

An update outside the automated merge allowlist can still pass individual
review. Major updates require compatibility review rather than automatic
rejection. Return decisions about support policy or public compatibility to the
user when they are outside the authorized scope or remain unresolved.

## Establish the batch

1. Check the checkout, branch, Git status, and worktree list.
2. List open Dependabot PRs and verify their actual author and update targets.
3. Separate candidates, exclusions, and holds.
4. For each candidate, record its PR number, old and new versions, head SHA,
   base SHA, changed files, CI results, and existing reviews.

Distinguish replacements for original candidates from unrelated PRs created
after the batch started. Review replacements within the original scope and
preserve exclusions. Report unrelated new updates rather than extending the
batch indefinitely.

## Review each PR

Process one PR at a time.

### Inspect the update

- Read official release notes and changelogs, and inspect upstream diffs when
  needed. Compare breaking changes with actual usage in this repository.
- Review the complete PR diff for unrelated edits, unexpected dependency
  updates, and changes to constraints, platforms, or sources.
- For Bundler updates, inspect Ruby requirements and transitive dependencies.
  When a shared dependency appears in both the root and optional ActiveSupport
  environments, verify consistency across both lockfiles.
- For Actions updates, verify that the pinned SHA corresponds to the intended
  official release. Review the Node runtime, inputs, outputs, script APIs,
  permissions, triggers, and executable code affected by the update.

### Refresh a stale branch

- Do not treat CI against an old base as validation against current master.
- If a refresh is needed, use one update mechanism at a time.
- After requesting `@dependabot rebase`, wait for the head to change or for
  Dependabot to report the outcome. Do not immediately also run
  `gh pr update-branch` or post another refresh request.
- Space status reads apart. If the operation remains pending, preserve that
  state and report it rather than repeatedly requesting the same update.
- Use `@dependabot recreate` when rebase has failed and regeneration is
  appropriate. Check for manual changes before allowing recreation to overwrite
  them; skip if their disposition is unclear.
- Bound retries: if one rebase attempt and one appropriate recreation attempt
  do not resolve the problem, skip the PR and record the reason.

Whenever the head changes, re-inspect the complete diff and obtain verification
results for the new head. Do not reuse approval based on a previous head.

### Verify and merge

- Use validation results associated with the current head and current base.
- Check required statuses and additional checks relevant to the update. Wait for
  downstream jobs, including coverage collation, to finish.
- Do not count pending, failed, unknown, or unexpectedly skipped checks as
  successful. Investigate expected skips before describing what was verified.
- Validate workflow changes with actionlint and zizmor. Compare existing
  findings with the base, distinguish new findings, and assess their relevance;
  an unchanged finding count alone is not proof of safety.
- Do not merge with unresolved review findings or compatibility concerns.
- Immediately before merging, re-read the open state, head SHA, base, all
  relevant checks, and `mergeStateStatus: CLEAN`.
- Merge with the inspected head SHA as an expected-head guard, using the
  repository's configured merge method. Confirm that GitHub reports success.
- If the expected head no longer matches, read the new state and review it
  rather than resending the same merge request. Never bypass protection or use
  an admin override to complete the batch.

## Skip or stop

Skip an update with a PR-specific problem and continue with independent
candidates. Return the decision to the user when:

- A public compatibility or support-policy change is needed.
- CI failures or security concerns cannot be resolved within scope.
- Unrelated edits are present and their intent cannot be established.
- Required verification results cannot be obtained.

If authentication or API failures prevent reliable review of the whole batch,
stop merging. Report completed and uncompleted work separately.

## Integration and resumption

- After each merge, check master CI. If integration fails, stop further merges
  and report the impact. Determine the cause and authorization before fixing,
  reverting, or rerunning anything.
- Verify the final master commit's CI before reporting the batch complete.
- On resumption, retrieve the current PR state, head, base, and CI results
  again. Do not rely on the pre-interruption snapshot.

## Completion report

Summarize:

- Each PR's update and its merged, skipped, excluded, or held disposition.
- Reasons for skips and decisions that require the user's judgment.
- The final master SHA and CI link.
- Verification performed and items that remain unverified.
- Documentation and implementation inconsistencies encountered during the task.
- A short Keep / Problem / Try retrospective.

Distinguish successful coverage collation from successful delivery to an
external service, and local test success from CI matrix success.
