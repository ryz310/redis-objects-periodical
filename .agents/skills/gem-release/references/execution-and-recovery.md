# Execution and recovery

Read this for tool setup, external mutations, or resumption. It supplements
[SKILL.md](../SKILL.md); it does not grant publication or configuration authority.

## Credential gate

Identify the authentication required by the requested actions before setup:

- gem_comet/pr_comet preparation normally needs `GITHUB_ACCESS_TOKEN` in the
  actual process and authenticated Git push access. A GitHub connector alone
  does not authenticate those tools. An already authorized CLI credential bridge
  may be used without printing or persisting the credential.
- Verify presence/nonemptiness, then use an authenticated read-only request to
  establish identity and repository access. Check non-secret permission metadata
  where available; anonymous access to this public repository proves nothing
  about write access. Verify the intended container/process boundary without
  installing or running release automation merely to test credentials.
- Full publication uses Actions OIDC through the configured Trusted Publisher
  and protected GitHub environment, rather than a local `RUBYGEMS_API_KEY`.
  Inspect the workflow and non-secret provisioning evidence. Do not request
  remote secret values, unrelated coverage credentials, or a local OIDC token.
  A full release also needs GitHub contents-write access for its final draft.
- On missing, empty, invalid, inaccessible, or unverifiable required
  authentication, stop all release execution immediately, including otherwise
  independent preparation. Network/API failure means verification failed, not
  that the credential is absent. A gate script must exit nonzero on failure.
  Report the mechanism and configuration location only; resume after the gate
  passes again. Recheck when the execution environment or auth path changes.

Offline review and skill authoring are exempt. Preparation-only work does not
require a live publisher, and gate success does not expand user authorization.

## Preflight the execution environment

Use the repository Compose `ruby` service and an isolated Compose project per
CONTRIBUTING.md. Read the current Ruby and Bundler versions from configuration.
Before a tool can mutate the mounted checkout, verify:

- The selected Ruby/Bundler, installed gem_comet/pr_comet versions and source,
  repository/branch, and effective `git user.name` / `user.email`. Some tool
  versions read Git config directly, so author environment variables alone may
  not suffice. Do not invent an identity.
- Container and host status agree. Host global ignore rules may be absent in
  Docker; inspect specific differences with `git check-ignore -v`. Preserve user
  files rather than deleting them or concealing edits with broad ignore rules.
- Linked-worktree Git metadata is reachable. A mount of the checkout alone may
  omit the shared Git directory; provide only the needed metadata access. Check
  `git ls-files` before package validation. Trust only the intended workspace
  when container Git ownership checks require `safe.directory`.
- The credential gate passed in this environment. Avoid environment dumps,
  `.env`/credential-store inspection, token-bearing remotes, command-line token
  arguments, persisted credentials, or shell tracing. Transfer required auth
  only through an approved process-scoped mechanism.

Keep optional tool installations outside the product Gemfile, bundle volume,
and tracked tree. Inspect tool behavior before CLI execution:

| Behavior to inspect | Required handling |
| --- | --- |
| Hard-coded `update/vVERSION` branch | Use supported CLI/configuration to satisfy the topic-branch policy; if unavailable, obtain a decision before mutation |
| Unrestricted `bundle update` | Check supported update controls before execution; if they cannot preserve the agreed scope, obtain a decision rather than run a bulk update or replace the updater |
| Git failures swallowed by the CLI | Check each stage's actual state; a zero exit code is insufficient |
| Merge-message-only changelog | Include squash-merged PRs and migration notes from the verified change set |
| Browser launch in a container | Report resulting PR links; no browser launch is required |

A wrapper may supply process-only environment settings, invoke the actual CLI,
capture its output, and check stage results. It must not replace CLI execution
with internal API calls or monkey-patch the release stages, branch behavior,
dependency updater, or generated CHANGELOG content. If the CLI cannot meet a
repository constraint, report that concrete limitation before running it.

## CLI and generation history

Use `gem_comet changelog` to inspect the generated notes, then
`gem_comet release VERSION` to create the Update and Release PRs. Do not run
both a file-prepending preview and the release's own generation in a way that
duplicates the release entry. Record the actual CLI commands, tool versions,
resulting PRs, and generated commit SHAs without credential values.

Keep the tool-generated CHANGELOG in its original commit before editorial
changes. After the CLI completes, review the generated entry and commit the
formatting/content corrections separately. Preserve those commits when pushing;
do not amend, squash, rebase away, or force-push the generation evidence unless
the user explicitly requests rewriting that history. A hand-edited file placed
in the first tool-created commit does not preserve the generated output.

During editorial review:

- Keep only the final Dependabot PR per dependency, with the versions from that
  particular update and the established contributor attribution. Use the PR's
  body/diff when its title omits the versions. Do not list intermediate PRs.
- Use consecutive `-` bullet lines with no empty lines between entries; keep
  the heading/category separation. Preserve other releases and unrelated text.
- Review categories, missing squash merges, compatibility notes, and migrations
  against the verified change set rather than treating generated text as final.

If a resumed release lacks an unedited generation commit, disclose that gap.
Do not manufacture an earlier commit or claim the edited commit is raw CLI
output. Preserve the existing history and add only the needed follow-up changes;
do not rerun the full release command merely to recreate missing evidence or
create duplicate PRs.

## Preserve PR content

For either release-related PR, fetch its current body before editing. Retain
human content and generated `# TODO` items, checkbox states, and
`Generated by [gem_comet](https://github.com/ryz310/gem_comet)` attribution.
Add purpose, compatibility, validation, and CLI execution notes around that
content; update an existing section instead of duplicating it.

Review the body diff before submission. After the reviewed CHANGELOG is present
in the current update PR diff, change only `- [ ] Edit the CHANGELOG.md` to
`- [x] Edit the CHANGELOG.md` without another confirmation. Preserve its wording
and all other states. Generation alone does not complete editing/review.
Re-fetch if concurrent edits are possible, reconcile changes, and read back the
submitted body. Supply Markdown through structured tools or `--body-file`.

## Record and resume stages

Keep progress evidence in the chat or PR, not a committed per-run state file:

| Stage | Evidence before continuing |
| --- | --- |
| Preparation | Actual CLI invocation, correct topic/base, scoped version/CHANGELOG/both lockfile diff |
| CHANGELOG review | Original generated commit followed by separate editorial commits; disclose any pre-existing evidence gap |
| Commit and push | Intended files committed; remote SHA equals local SHA |
| Update PR | Correct head/base and successful exact-head checks |
| Release PR | Configured base to publication branch; intended full delta and current-head checks |
| Merge authorization | Direct user instruction covering the specific Update or Release PR, or explicitly both stages; CI/setup confirmation alone is insufficient |
| Publish trigger | Explicitly approved Release PR merge and its resulting workflow/commit |
| Published artifacts | Successful publishing job, tag commit, RubyGems metadata/checksum/package |
| Release draft | Existing verified tag, reviewed notes, matching SHA and `draft: true` |

On resumption, run the credential gate first, then inspect actual Git/PR/run/tag/
RubyGems state. Reuse completed stages. If the release PR exists without an
update PR, create only the missing preparation PR; the existing release PR is
not ready to publish. Inspect uncommitted generated work before repairing or
regenerating only task-owned changes. Never reset unrelated user work.

Resumption does not grant merge authority. Re-read existing direct user merge
instructions and preserve their scope; Update approval does not extend to the
Release PR. Leave an unapproved stage open, without auto-merge, queue enrollment,
or an alternative publication trigger. Reuse an explicit instruction covering
both stages without asking for the same approval again.

After a failed, explicitly authorized merge request, read the PR state before
retrying: the merge may already have succeeded. A head change requires fresh
diff and CI review and a check that authorization still covers its contents.
If the same stage fails again after one targeted repair, stop automatic retries
and report the remaining prerequisite or decision. Authentication failure stops
all release execution; otherwise continue only independent authorized work.

For a failed publishing run, inspect both tag and RubyGems version before any
retry. A tag-only or gem-only result is a partial publication, not a fresh run.
Do not delete/move tags, yank/reuse a version, bypass protection, or manually
dispatch another publisher as automatic recovery. Diagnose the failed stage
and obtain any missing decision before a narrowly scoped retry. A draft-only
failure after gem publication requires recovery of the draft stage alone.

## Final GitHub Release draft

After successful gem publication and tag verification:

1. Read CHANGELOG from the verified tag's commit. Select the matching version
   section through the next level-two heading. Use its heading without `## ` as
   the title and its category content as the body; retain its date, links,
   migration notes, and category order. Check previous Releases for presentation
   style, not version values. Save notes in a temporary Markdown file.
2. List authenticated Releases including drafts for this exact tag. Reuse a
   matching draft and preserve human edits. If already published, report the
   existing Release rather than duplicating or converting it to a draft.
3. For a missing Release, use the verified existing tag, for example:

   ```sh
   gh release create "$release_tag" --repo ryz310/redis-objects-periodical \
     --verify-tag --draft --title "$release_title" --notes-file "$release_notes_file"
   ```

   `--verify-tag` prevents implicit tag creation. Set prerelease status explicitly
   for a prerelease version. Do not attach arbitrary locally built packages or
   publish the draft as part of this step.
4. Read back tag, peeled commit SHA, title/body, prerelease flag, and `draft: true`.
   Report the URL separately from the published gem. Preparation-only requests
   stop at their PR handoff and do not create this final artifact early.

## Tool findings

For reproducible gem_comet/pr_comet defects, inspect installed and upstream code
and search existing issues before proposing a report. Route generic Git/PR
failure propagation to pr_comet and release sequencing, dependency controls,
and changelog handling to gem_comet. Include minimal non-secret evidence,
expected behavior, workaround, and meaningful regression coverage. Issue
posting and tool fixes require authorization covering those actions. Any proposed
workaround must preserve actual CLI execution and the merge-approval boundaries;
do not silently substitute an internal service or custom release implementation.
