'use strict';

const { evaluate } = require('./dependabot-policy.cjs');
const workflowPath = '.github/workflows/dependabot-auto-merge.yml';
const markerPrefix = 'Dependabot auto-merge policy reservation\n\n';

function reservationBody(context) {
  return markerPrefix + JSON.stringify({
    version: 1, workflow: workflowPath,
    repository: `${context.repo.owner}/${context.repo.repo}`,
    number: context.payload.pull_request.number,
    head: context.payload.pull_request.head.sha,
    run: String(context.runId),
  });
}

async function readState(github, context) {
  const result = await github.graphql(`query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        id state headRefOid baseRefName mergeStateStatus
        autoMergeRequest { enabledAt enabledBy { login __typename } commitBody mergeMethod }
      }
    }
  }`, { ...context.repo, number: context.payload.pull_request.number });
  const pr = result.repository && result.repository.pullRequest;
  if (!pr || !pr.id || !pr.headRefOid || !Object.hasOwn(pr, 'autoMergeRequest')) {
    throw new Error('Cannot verify current auto-merge state; inspect the PR manually.');
  }
  return pr;
}

function validOwnershipMarker(marker, context) {
  const matchesWorkflow = marker.version === 1 && marker.workflow === workflowPath;
  const matchesPullRequest = marker.repository === `${context.repo.owner}/${context.repo.repo}` &&
    marker.number === context.payload.pull_request.number;
  const validIdentity = /^[a-f0-9]{40}$/.test(marker.head) && /^[1-9][0-9]*$/.test(marker.run);
  return matchesWorkflow && matchesPullRequest && validIdentity;
}

async function ownedReservation(github, context, reservation) {
  if (!reservation) return false;
  if (reservation.enabledBy?.login !== 'github-actions[bot]' ||
      reservation.enabledBy.__typename !== 'Bot' ||
      !reservation.commitBody?.startsWith(markerPrefix)) return false;
  let marker;
  try { marker = JSON.parse(reservation.commitBody.slice(markerPrefix.length)); }
  catch { return false; }
  if (!validOwnershipMarker(marker, context)) return false;
  // GITHUB_TOKEN is shared across workflows: verify the marker's run provenance too.
  const { data: run } = await github.rest.actions.getWorkflowRun({
    ...context.repo, run_id: marker.run,
  });
  return String(run.id) === marker.run && run.path === workflowPath &&
    run.event === 'pull_request_target' &&
    run.repository?.full_name === marker.repository;
}

function sameReservation(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

async function revoke({ github, context, core, state }) {
  if (!state.autoMergeRequest) return;
  if (!await ownedReservation(github, context, state.autoMergeRequest)) {
    core.notice('Preserving an unowned or legacy auto-merge reservation. Inspect it manually before merging.');
    return;
  }
  // No conditional-disable mutation exists. Serialize this workflow's runs and
  // re-read immediately before mutation; external writers must not race recovery.
  const current = await readState(github, context);
  if (!current.autoMergeRequest) return;
  if (current.headRefOid !== context.payload.pull_request.head.sha ||
      !sameReservation(current.autoMergeRequest, state.autoMergeRequest)) {
    throw new Error('PR head or reservation changed before cancellation; inspect auto-merge manually.');
  }
  await github.graphql(`mutation($id: ID!) {
    disablePullRequestAutoMerge(input: {pullRequestId: $id}) {
      pullRequest { id autoMergeRequest { enabledAt } }
    }
  }`, { id: current.id });
  const after = await readState(github, context);
  if (after.autoMergeRequest) {
    throw new Error('Auto-merge cancellation was not confirmed; disable auto-merge manually.');
  }
  core.notice('Revoked this workflow\'s auto-merge reservation.');
}

function cleanStatusError(error) {
  // Octokit preserves the structured GraphQL errors separately from Error.message.
  if (error.name !== 'GraphqlResponseError' || !Array.isArray(error.errors) ||
      error.errors.length !== 1) return false;
  const failure = error.errors[0];
  return failure.type === 'UNPROCESSABLE' &&
    JSON.stringify(failure.path) === JSON.stringify(['enablePullRequestAutoMerge']) &&
    failure.message === 'Pull request Pull request is in clean status';
}

async function mergeCleanUpdate({ github, context, core, metadata }) {
  // Repeat the entire policy/protection check; the PR base can change without a
  // new head OID. A fresh final snapshot also preserves newly created reservations.
  if (!await evaluate({ github, context, core, metadata })) {
    throw new Error('Policy changed after the clean-status response; inspect the PR manually.');
  }
  const current = await readState(github, context);
  const sameTarget = current.headRefOid === context.payload.pull_request.head.sha &&
    current.baseRefName === 'master';
  const ready = current.state === 'OPEN' && current.mergeStateStatus === 'CLEAN';
  if (!sameTarget || !ready || current.autoMergeRequest) {
    throw new Error('PR state changed before the clean-status merge; inspect the PR manually.');
  }
  const result = await github.graphql(`mutation($id: ID!, $head: GitObjectID!) {
    mergePullRequest(input: {pullRequestId: $id, expectedHeadOid: $head, mergeMethod: MERGE}) {
      pullRequest { id headRefOid merged }
    }
  }`, { id: current.id, head: current.headRefOid });
  const merged = result.mergePullRequest?.pullRequest;
  if (merged?.merged !== true || merged.headRefOid !== current.headRefOid) {
    throw new Error('Could not confirm the clean-status merge; inspect the PR manually.');
  }
  core.notice('Merged the inspected head after all required checks passed.');
}

async function reconcileState({ github, context, core, metadata, metadataOutcome }) {
  const state = await readState(github, context);
  if (state.headRefOid !== context.payload.pull_request.head.sha) {
    core.notice('Stale event: preserving the current head\'s auto-merge state.');
    return;
  }
  let safe = false;
  let verificationError;
  try {
    if (metadataOutcome !== 'success') throw new Error('Dependabot metadata retrieval failed.');
    safe = await evaluate({ github, context, core, metadata });
  } catch (error) { verificationError = error; }

  if (!safe) {
    await revoke({ github, context, core, state });
    if (verificationError) {
      throw new Error(`Policy verification failed; check the PR's auto-merge state: ${verificationError.message}`);
    }
    core.notice('Update requires manual review.');
    return;
  }

  const current = await readState(github, context);
  if (current.headRefOid !== context.payload.pull_request.head.sha || current.state !== 'OPEN') {
    core.notice('PR changed during verification; no reservation created.');
    return;
  }
  if (current.autoMergeRequest) {
    core.notice('Preserving the existing auto-merge reservation.');
    return;
  }
  let result;
  try {
    result = await github.graphql(`mutation($id: ID!, $head: GitObjectID!, $body: String!) {
      enablePullRequestAutoMerge(input: {
        pullRequestId: $id, expectedHeadOid: $head, mergeMethod: MERGE, commitBody: $body
      }) { pullRequest { id headRefOid autoMergeRequest { commitBody } } }
    }`, { id: current.id, head: current.headRefOid, body: reservationBody(context) });
  } catch (error) {
    if (!cleanStatusError(error)) throw error;
    await mergeCleanUpdate({ github, context, core, metadata });
    return;
  }
  const enabled = result.enablePullRequestAutoMerge?.pullRequest;
  if (enabled?.headRefOid !== current.headRefOid ||
      enabled.autoMergeRequest?.commitBody !== reservationBody(context)) {
    throw new Error('Could not verify the new reservation; inspect auto-merge manually.');
  }
  core.notice('Reserved auto-merge for the inspected head.');
}

async function reconcile(input) {
  try { await reconcileState(input); }
  catch (error) {
    throw new Error(`Auto-merge reconciliation failed; inspect the PR and disable an unsafe reservation manually: ${error.message}`);
  }
}

module.exports = { reconcile, reservationBody, ownedReservation };
