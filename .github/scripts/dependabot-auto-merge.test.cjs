'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { reconcile, reservationBody, ownedReservation } = require('./dependabot-auto-merge.cjs');
const { requiredChecks } = require('./dependabot-policy.cjs');

function harness() {
  const context = { repo: { owner: 'ryz310', repo: 'redis-objects-periodical' }, runId: 123,
    payload: { pull_request: { number: 1, head: { sha: 'a'.repeat(40) } } } };
  const reservation = { enabledAt: '2026-10-27T00:00:00Z',
    enabledBy: { login: 'github-actions[bot]', __typename: 'Bot' },
    commitBody: reservationBody(context), mergeMethod: 'MERGE' };
  const state = { id: 'PR_node', state: 'OPEN', headRefOid: 'a'.repeat(40), autoMergeRequest: reservation };
  const calls = [], notices = [], states = [];
  const pr = { number: 1, user: { login: 'dependabot[bot]' }, state: 'open', draft: false,
    base: { ref: 'master', sha: 'base', repo: { full_name: 'ryz310/redis-objects-periodical' } },
    head: { sha: state.headRefOid, repo: { full_name: 'ryz310/redis-objects-periodical' } }, changed_files: 1 };
  const run = { id: 123, path: '.github/workflows/dependabot-auto-merge.yml',
    event: 'pull_request_target', repository: { full_name: 'ryz310/redis-objects-periodical' } };
  const github = {
    rest: { pulls: { get: async () => ({ data: pr }), listFiles: 'files' },
      actions: { getWorkflowRun: async () => ({ data: run }) } },
    paginate: async endpoint => endpoint === 'files' ? [{ filename: '.github/workflows/ci.yml', status: 'modified',
      additions: 1, deletions: 1, patch: '@@ -1 +1 @@\n-  uses: actions/checkout@' + 'a'.repeat(40) +
        '\n+  uses: actions/checkout@' + 'b'.repeat(40) }] : [],
    graphql: async (query, variables) => {
      if (query.includes('disablePullRequestAutoMerge')) {
        calls.push(['disable', variables]); state.autoMergeRequest = null;
        return { disablePullRequestAutoMerge: { pullRequest: state } };
      }
      if (query.includes('enablePullRequestAutoMerge')) {
        calls.push(['enable', variables]);
        state.autoMergeRequest = { ...reservation, commitBody: variables.body };
        return { enablePullRequestAutoMerge: { pullRequest: state } };
      }
      if (query.includes('autoMergeRequest')) return { repository: { pullRequest: states.shift() || structuredClone(state) } };
      return { repository: { autoMergeAllowed: true, ref: { branchProtectionRule: {
        requiresStatusChecks: true, requiresStrictStatusChecks: true, requiredStatusCheckContexts: requiredChecks,
      } } } };
    },
  };
  return { github, context, core: { notice: message => notices.push(message) },
    metadata: { ecosystem: 'github-actions', updateType: 'version-update:semver-major', dependencyNames: 'actions/checkout' },
    metadataOutcome: 'success', state, reservation, states, pr, run, calls, notices };
}

test('revokes an owned reservation when the current-head update is rejected', async () => {
  const input = harness(); await reconcile(input);
  assert.deepEqual(input.calls, [['disable', { id: 'PR_node' }]]);
  assert.equal(input.state.autoMergeRequest, null);
});
for (const scenario of ['no-reservation', 'already-disabled']) {
  test(`rejection tolerates ${scenario}`, async () => {
    const input = harness();
    if (scenario === 'no-reservation') input.state.autoMergeRequest = null;
    else input.states.push(structuredClone(input.state), { ...input.state, autoMergeRequest: null });
    await reconcile(input); assert.deepEqual(input.calls, []);
  });
}
for (const scenario of ['human', 'other-workflow', 'legacy', 'wrong-repo', 'wrong-pr', 'malformed', 'wrong-event', 'wrong-run']) {
  test(`preserves ${scenario} reservations`, async () => {
    const input = harness();
    if (scenario === 'human') input.reservation.enabledBy = { login: 'maintainer', __typename: 'User' };
    if (scenario === 'other-workflow') input.run.path = '.github/workflows/another.yml';
    if (scenario === 'legacy') input.reservation.commitBody = 'Existing merge message';
    if (scenario === 'wrong-repo') input.reservation.commitBody = reservationBody({ ...input.context, repo: { owner: 'other', repo: 'repo' } });
    if (scenario === 'wrong-pr') input.reservation.commitBody = reservationBody({ ...input.context,
      payload: { pull_request: { number: 2, head: { sha: 'a'.repeat(40) } } } });
    if (scenario === 'malformed') input.reservation.commitBody = 'Dependabot auto-merge policy reservation\n\n{';
    if (scenario === 'wrong-event') input.run.event = 'push';
    if (scenario === 'wrong-run') input.run.id = 124;
    await reconcile(input); assert.deepEqual(input.calls, []);
    assert.ok(input.notices.some(message => message.includes('Inspect it manually')));
  });
}
for (const scenario of ['metadata', 'evaluation']) {
  test(`revokes on ${scenario} failure and still fails visibly`, async () => {
    const input = harness();
    if (scenario === 'metadata') input.metadataOutcome = 'failure';
    else input.github.paginate = async () => { throw new Error('API unavailable'); };
    await assert.rejects(reconcile(input), /Policy verification failed/);
    assert.equal(input.calls[0][0], 'disable');
  });
}
test('stale events preserve a newer successfully evaluated reservation', async () => {
  const input = harness(); input.state.headRefOid = 'b'.repeat(40);
  input.state.autoMergeRequest.commitBody = reservationBody({ ...input.context,
    payload: { pull_request: { number: 1, head: { sha: 'b'.repeat(40) } } } });
  input.github.paginate = async () => { throw new Error('Must not evaluate stale event'); };
  await reconcile(input); assert.deepEqual(input.calls, []);
});
for (const scenario of ['head', 'reservation']) {
  test(`refuses to cancel after concurrent ${scenario} change`, async () => {
    const input = harness(); const changed = structuredClone(input.state);
    if (scenario === 'head') changed.headRefOid = 'b'.repeat(40);
    else changed.autoMergeRequest.enabledAt = '2026-10-27T01:00:00Z';
    input.states.push(structuredClone(input.state), changed);
    await assert.rejects(reconcile(input), /changed before cancellation/);
    assert.deepEqual(input.calls, []);
  });
}
for (const scenario of ['cancellation-error', 'cancellation-unconfirmed', 'provenance-error', 'initial-read-error', 'verification-read-error']) {
  test(`fails visibly on ${scenario}`, async () => {
    const input = harness(); const graphql = input.github.graphql;
    if (scenario === 'provenance-error') input.github.rest.actions.getWorkflowRun = async () => { throw new Error('Forbidden'); };
    else input.github.graphql = async (query, variables) => {
      if (scenario === 'cancellation-error' && query.includes('disablePullRequestAutoMerge')) throw new Error('Forbidden');
      if (scenario === 'cancellation-unconfirmed' && query.includes('disablePullRequestAutoMerge')) return {};
      if (scenario === 'initial-read-error') throw new Error('Forbidden');
      if (scenario === 'verification-read-error' && input.calls.length) throw new Error('Forbidden');
      return graphql(query, variables);
    };
    await assert.rejects(reconcile(input), /Forbidden|cancellation was not confirmed/);
  });
}
test('safe updates reserve with an atomic expected-head guard and ownership body', async () => {
  const input = harness(); input.state.autoMergeRequest = null;
  input.metadata.updateType = 'version-update:semver-patch';
  await reconcile(input);
  assert.deepEqual(input.calls, [['enable', { id: 'PR_node', head: 'a'.repeat(40), body: reservationBody(input.context) }]]);
});
test('safe updates preserve existing reservations including human-owned ones', async () => {
  const input = harness(); input.metadata.updateType = 'version-update:semver-patch';
  input.reservation.enabledBy = { login: 'maintainer', __typename: 'User' };
  await reconcile(input); assert.deepEqual(input.calls, []);
});
test('head change during a successful evaluation cannot enable a reservation', async () => {
  const input = harness(); input.state.autoMergeRequest = null;
  input.metadata.updateType = 'version-update:semver-patch';
  input.states.push(structuredClone(input.state), { ...input.state, headRefOid: 'b'.repeat(40) });
  await reconcile(input); assert.deepEqual(input.calls, []);
});
test('ownership requires workflow run provenance beyond the shared bot identity', async () => {
  const input = harness();
  assert.equal(await ownedReservation(input.github, input.context, input.reservation), true);
  input.run.repository.full_name = 'other/repo';
  assert.equal(await ownedReservation(input.github, input.context, input.reservation), false);
});

for (const scenario of ['enable-error', 'null-response', 'missing-reservation', 'wrong-head']) {
  test(`fails visibly on ${scenario} after an eligible evaluation`, async () => {
    const input = harness(); input.state.autoMergeRequest = null;
    input.metadata.updateType = 'version-update:semver-patch';
    const graphql = input.github.graphql;
    input.github.graphql = async (query, variables) => {
      if (!query.includes('enablePullRequestAutoMerge')) return graphql(query, variables);
      if (scenario === 'enable-error') throw new Error('Forbidden');
      if (scenario === 'null-response') return { enablePullRequestAutoMerge: null };
      if (scenario === 'missing-reservation') return { enablePullRequestAutoMerge: { pullRequest: input.state } };
      return { enablePullRequestAutoMerge: { pullRequest: { ...input.state,
        headRefOid: 'b'.repeat(40), autoMergeRequest: input.reservation } } };
    };
    await assert.rejects(reconcile(input), /inspect the PR.*(?:Forbidden|Could not verify)/);
  });
}

test('metadata retrieval failure still fails when no reservation exists', async () => {
  const input = harness(); input.state.autoMergeRequest = null; input.metadataOutcome = 'failure';
  await assert.rejects(reconcile(input), /metadata retrieval failed/);
  assert.deepEqual(input.calls, []);
});

test('privileged workflow keeps trusted-base execution and failure cleanup wired', () => {
  const { readFileSync } = require('node:fs');
  const { join } = require('node:path');
  const workflow = readFileSync(join(__dirname, '../workflows/dependabot-auto-merge.yml'), 'utf8');
  assert.match(workflow, /cancel-in-progress: false/);
  assert.match(workflow, /ref: \$\{\{ github.event.pull_request.base.sha \}\}/);
  assert.doesNotMatch(workflow, /ref:.*pull_request.head/);
  assert.match(workflow, /if: \$\{\{ always\(\) && steps.policy_checkout.outcome == 'success' \}\}/);
  assert.match(workflow, /METADATA_OUTCOME: \$\{\{ steps.metadata.outcome \}\}/);
  assert.match(workflow, /await reconcile\(/);
});
