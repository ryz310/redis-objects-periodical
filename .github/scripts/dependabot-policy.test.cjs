'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { assessUpdate, protectionReady, evaluate, requiredChecks } = require('./dependabot-policy.cjs');

const metadata = {
  ecosystem: 'bundler', updateType: 'version-update:semver-patch', dependencyNames: 'rspec',
};
const baseLock = `PATH
  remote: .
  specs:
    redis-objects-periodical (0.7.0)
      redis-objects (~> 1.0)

GEM
  remote: https://rubygems.org/
  specs:
    connection_pool (2.3.0)
    redis (5.0.6)
      redis-client (>= 0.9.0)
    redis-client (0.12.1)
      connection_pool
    redis-objects (1.7.0)
      redis
    rspec (3.13.1)
      rspec-core (~> 3.13.0)

BUNDLED WITH
  4.0.23
`;
const headLock = baseLock.replace('rspec (3.13.1)', 'rspec (3.13.2)');
const file = (filename, removed, added) => ({
  filename, status: 'modified', deletions: removed.length, additions: added.length,
  patch: ['@@ -1,1 +1,1 @@', ...removed.map(line => '-' + line), ...added.map(line => '+' + line)].join('\n'),
});
const lockFile = file('Gemfile.lock', ['    rspec (3.13.1)'], ['    rspec (3.13.2)']);
const lockInput = { metadata, files: [lockFile], baseLock, headLock };
// Representative outputs from the pinned dependabot/fetch-metadata action:
// src/dependabot/update_metadata.ts derives this ecosystem from dependabot/github_actions/...
const actionOutputs = {
  'package-ecosystem': 'github_actions',
  'update-type': 'version-update:semver-patch',
  'dependency-names': 'actions/checkout',
};
const actionMetadata = {
  ecosystem: actionOutputs['package-ecosystem'],
  updateType: actionOutputs['update-type'],
  dependencyNames: actionOutputs['dependency-names'],
};
const actionFile = file('.github/workflows/ci.yml',
  ['      - uses: actions/checkout@' + 'a'.repeat(40) + ' # v6.0.0'],
  ['      - uses: actions/checkout@' + 'b'.repeat(40) + ' # v6.0.1']);
const actionInput = { metadata: actionMetadata, files: [actionFile] };

test('permits an allowlisted development lockfile patch or minor', () => {
  assert.equal(assessUpdate(lockInput), true);
  assert.equal(assessUpdate({ ...lockInput, metadata: { ...metadata, updateType: 'version-update:semver-minor' } }), true);
});
for (const name of ['redis-objects', 'redis', 'bundler', 'activesupport', 'unknown', 'rspec, redis-objects', '']) {
  test(`rejects unapproved dependency list ${JSON.stringify(name)}`, () => {
    assert.equal(assessUpdate({ ...lockInput, metadata: { ...metadata, dependencyNames: name } }), false);
  });
}
for (const updateType of ['version-update:semver-major', '', 'unknown']) {
  test(`rejects update type ${JSON.stringify(updateType)}`, () => {
    assert.equal(assessUpdate({ ...lockInput, metadata: { ...metadata, updateType } }), false);
  });
}
test('requires every dependency in a grouped update to be allowlisted', () => {
  assert.equal(assessUpdate({ ...lockInput, metadata: { ...metadata, dependencyNames: 'rspec, yard' } }), true);
});
for (const filename of ['Gemfile', 'redis-objects-periodical.gemspec', 'gemfiles/active_support/Gemfile', 'gemfiles/active_support/Gemfile.lock', 'lib/redis-objects-periodical.rb']) {
  test(`rejects manifest, integration, or implementation edits: ${filename}`, () => {
    assert.equal(assessUpdate({ ...lockInput, files: [{ ...lockFile, filename }] }), false);
  });
}
test('rejects any additional file, even alongside a valid lockfile change', () => {
  assert.equal(assessUpdate({ ...lockInput, files: [lockFile, { ...lockFile, filename: 'Gemfile' }] }), false);
});
test('keeps a shared dependency update in both lockfiles under manual review', () => {
  const integrationLock = { ...lockFile, filename: 'gemfiles/active_support/Gemfile.lock' };
  assert.equal(assessUpdate({ ...lockInput, files: [lockFile, integrationLock] }), false);
});
for (const name of ['connection_pool', 'redis', 'redis-client', 'redis-objects', 'redis-objects-periodical']) {
  test(`rejects changes to protected runtime entry ${name}`, () => {
    const altered = headLock.replace(new RegExp(`(    ${name} \\()[^)]*`), (_, prefix) => prefix + '99.0.0');
    assert.equal(assessUpdate({ ...lockInput, headLock: altered }), false);
  });
}
for (const [removed, added] of [
  ['  remote: https://rubygems.org/', '  remote: https://example.com/'],
  ['  4.0.23', '  4.1.0'],
  ['  rspec (~> 3.13)', '  rspec (~> 4.0)'],
  ['  x86_64-linux', '  other-platform'],
]) {
  test(`rejects lockfile control changes: ${removed.trim()}`, () => {
    assert.equal(assessUpdate({ ...lockInput, files: [file('Gemfile.lock', [removed], [added])] }), false);
  });
}
test('rejects absent, truncated, added or deleted files', () => {
  for (const change of [{ patch: undefined }, { additions: 100 }, { status: 'added' }, { status: 'removed' }]) {
    assert.equal(assessUpdate({ ...lockInput, files: [{ ...lockFile, ...change }] }), false);
  }
  assert.equal(assessUpdate({ ...lockInput, files: [] }), false);
  assert.equal(assessUpdate({ ...lockInput, baseLock: '' }), false);
});
test('permits only pinned official action version replacements', () => {
  assert.equal(assessUpdate(actionInput), true);
});
test('rejects tags, third-party actions, privileges, triggers, steps and missing patches', () => {
  for (const added of [
    '      - uses: actions/checkout@v6.0.1',
    '      - uses: other/checkout@' + 'b'.repeat(40),
    'permissions: write-all', '  pull_request_target:', '      - run: echo unsafe',
  ]) {
    const unsafe = file(actionFile.filename, ['      - uses: actions/checkout@' + 'a'.repeat(40)], [added]);
    assert.equal(assessUpdate({ ...actionInput, files: [unsafe] }), false);
  }
  assert.equal(assessUpdate({ ...actionInput, files: [{ ...actionFile, patch: undefined }] }), false);
  assert.equal(assessUpdate({ ...actionInput, metadata: { ...actionMetadata, dependencyNames: 'actions/checkout, ruby/setup-ruby' } }), false);
});
test('rejects an official-action PR that also alters permissions', () => {
  const unsafe = file(actionFile.filename,
    ['      - uses: actions/checkout@' + 'a'.repeat(40), '  contents: read'],
    ['      - uses: actions/checkout@' + 'b'.repeat(40), '  contents: write']);
  assert.equal(assessUpdate({ ...actionInput, files: [unsafe] }), false);
});
for (const ecosystem of ['github-actions', 'github_action', '', 'unknown']) {
  test(`rejects an unrecognized Actions ecosystem ${JSON.stringify(ecosystem)}`, () => {
    assert.equal(assessUpdate({ ...actionInput, metadata: { ...actionMetadata, ecosystem } }), false);
  });
}
test('rejects unknown ecosystems and non-workflow action changes', () => {
  assert.equal(assessUpdate({ ...actionInput, metadata: { ...actionMetadata, ecosystem: 'docker' } }), false);
  assert.equal(assessUpdate({ ...actionInput, files: [{ ...actionFile, filename: '.github/scripts/policy.cjs' }] }), false);
});

const repository = {
  autoMergeAllowed: true,
  ref: { branchProtectionRule: {
    requiresStatusChecks: true, requiresStrictStatusChecks: true,
    requiredStatusCheckContexts: requiredChecks,
  } },
};
test('requires auto-merge and every documented strict required check', () => {
  assert.equal(protectionReady(repository), true);
  assert.equal(Boolean(protectionReady({ ...repository, autoMergeAllowed: false })), false);
  assert.equal(Boolean(protectionReady({ ...repository, ref: null })), false);
  for (const name of requiredChecks) {
    const protection = { ...repository.ref.branchProtectionRule,
      requiredStatusCheckContexts: requiredChecks.filter(check => check !== name) };
    assert.equal(protectionReady({ ...repository, ref: { branchProtectionRule: protection } }), false);
  }
  assert.equal(protectionReady({ ...repository, ref: { branchProtectionRule: {
    ...repository.ref.branchProtectionRule, requiresStrictStatusChecks: false,
  } } }), false);
});

function harness() {
  const pr = { number: 1, user: { login: 'dependabot[bot]' }, state: 'open', draft: false,
    base: { ref: 'master', sha: 'base', repo: { full_name: 'ryz310/redis-objects-periodical' } },
    head: { sha: 'head', repo: { full_name: 'ryz310/redis-objects-periodical' } }, changed_files: 1 };
  const context = { repo: { owner: 'ryz310', repo: 'redis-objects-periodical' },
    payload: { pull_request: { number: 1, head: { sha: 'head' } } } };
  const github = {
    rest: { pulls: { get: async () => ({ data: pr }), listFiles: 'files' }, repos: {
      getContent: async ({ ref }) => ({ data: { encoding: 'base64',
        content: Buffer.from(ref === 'base' ? baseLock : headLock).toString('base64') } }),
    } },
    paginate: async endpoint => endpoint === 'files' ? [lockFile] : [],
    graphql: async () => ({ repository }),
  };
  return { pr, github, context, core: { notice() {} }, metadata };
}
test('reads current PR and both immutable lockfile revisions without API writes', async () => {
  assert.equal(await evaluate(harness()), true);
});
for (const scenario of ['human', 'fork', 'stale', 'release', 'closed', 'draft', 'missing-files']) {
  test(`rejects current PR state: ${scenario}`, async () => {
    const input = harness();
    if (scenario === 'human') input.pr.user.login = 'someone';
    if (scenario === 'fork') input.pr.head.repo.full_name = 'someone/fork';
    if (scenario === 'stale') input.pr.head.sha = 'new-head';
    if (scenario === 'release') input.pr.base.ref = 'release';
    if (scenario === 'closed') input.pr.state = 'closed';
    if (scenario === 'draft') input.pr.draft = true;
    if (scenario === 'missing-files') input.pr.changed_files = 2;
    assert.equal(await evaluate(input), false);
  });
}
test('API or branch protection read failure cannot produce an approval', async () => {
  const input = harness();
  input.github.graphql = async () => { throw new Error('Forbidden'); };
  await assert.rejects(evaluate(input), /Forbidden/);
});

const rules = [{ type: 'required_status_checks', parameters: {
  strict_required_status_checks_policy: true,
  required_status_checks: requiredChecks.map(context => ({ context })),
} }];
const rulesRepository = { autoMergeAllowed: true, ref: { branchProtectionRule: null } };
test('accepts effective rulesets without requiring classic branch protection', () => {
  assert.equal(protectionReady(rulesRepository, rules), true);
});
test('rulesets must require every check and strict updates', () => {
  assert.equal(protectionReady(rulesRepository, [{ type: 'required_status_checks', parameters: {
    ...rules[0].parameters, strict_required_status_checks_policy: false,
  } }]), false);
  for (const name of requiredChecks) {
    assert.equal(protectionReady(rulesRepository, [{ type: 'required_status_checks', parameters: {
      ...rules[0].parameters,
      required_status_checks: rules[0].parameters.required_status_checks.filter(check => check.context !== name),
    } }]), false);
  }
});
test('rejects merge queues even with all checks configured', () => {
  assert.equal(protectionReady(repository, [...rules, { type: 'merge_queue' }]), false);
});
test('checks effective branch rules before approving an update', async () => {
  const input = harness();
  input.github.graphql = async () => ({ repository: rulesRepository });
  input.github.paginate = async endpoint => endpoint === 'files' ? [lockFile] : rules;
  assert.equal(await evaluate(input), true);
});

test('required Ruby checks match the reusable CI matrix', () => {
  const workflow = readFileSync(join(__dirname, '../workflows/checks.yml'), 'utf8');
  const matrix = workflow.match(/ruby:\s*\[([^\]]+)\]/);
  assert.ok(matrix, 'Expected an explicit Ruby matrix in checks.yml');
  const versions = matrix[1].split(',').map(value => value.trim().replace(/['"]/g, ''));
  assert.deepEqual(requiredChecks.filter(name => name.startsWith('checks / build_on_ruby_')),
    versions.map(version => `checks / build_on_ruby_${version}`));
});
