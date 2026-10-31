'use strict';

const developmentGems = new Set([
  'pry-byebug', 'rake', 'rspec', 'rspec_junit_formatter', 'rubocop',
  'rubocop-performance', 'rubocop-rspec', 'simplecov', 'timecop', 'yard',
]);
const officialActions = new Set([
  'actions/checkout', 'actions/upload-artifact', 'actions/download-artifact',
  'actions/github-script',
]);
const requiredChecks = [
  'checks / build_on_ruby_3.3', 'checks / build_on_ruby_3.4', 'checks / build_on_ruby_4.0',
  'checks / rubocop', 'yardoc', 'upload-coverage', 'active-support-timezone', 'dependabot-policy',
];

function changedLines(file) {
  if (file.status !== 'modified' || !file.patch) return null;
  const lines = file.patch.split('\n');
  const removed = lines.filter(line => line.startsWith('-')).map(line => line.slice(1));
  const added = lines.filter(line => line.startsWith('+')).map(line => line.slice(1));
  // Missing or truncated patches must never turn an incomplete inspection into approval.
  if (removed.length !== file.deletions || added.length !== file.additions) return null;
  return { removed, added };
}

function protectedLockEntries(lock) {
  // Runtime dependencies from the gemspec and their locked dependency closure.
  const entries = [...lock.matchAll(/^    (?:redis-objects-periodical|redis-objects|redis|redis-client|connection_pool) \([^\n]+\)\n(?: {6}[^\n]+\n)*/gm)];
  return entries.map(entry => entry[0]).sort();
}

function assessUpdate({ metadata, files, baseLock = '', headLock = '' }) {
  const smallUpdate = ['version-update:semver-patch', 'version-update:semver-minor'];
  if (!smallUpdate.includes(metadata.updateType)) return false;
  const names = metadata.dependencyNames.split(',').map(name => name.trim()).filter(Boolean);
  if (names.length === 0 || files.length === 0) return false;

  if (metadata.ecosystem === 'bundler') {
    if (!names.every(name => developmentGems.has(name))) return false;
    // Manifest/constraint edits, optional integration dependencies, and Bundler stay manual.
    if (files.length !== 1 || files[0].filename !== 'Gemfile.lock') return false;
    const lines = changedLines(files[0]);
    if (!lines || !baseLock || !headLock) return false;
    const before = protectedLockEntries(baseLock);
    const after = protectedLockEntries(headLock);
    if (before.length !== 5 || JSON.stringify(before) !== JSON.stringify(after)) return false;
    // Only gem spec/version and dependency requirement lines may change, never sources,
    // platforms, direct constraints, PATH entries, or BUNDLED WITH.
    return [...lines.removed, ...lines.added].every(line =>
      /^    [\w-]+ \([0-9][^)]*\)$/.test(line) || /^      [\w-]+(?: \([^)]*\))?$/.test(line));
  }

  if (metadata.ecosystem !== 'github_actions' || !names.every(name => officialActions.has(name))) {
    return false;
  }
  return files.every(file => {
    if (!/^\.github\/workflows\/[^/]+\.ya?ml$/.test(file.filename)) return false;
    const lines = changedLines(file);
    if (!lines || lines.removed.length === 0 || lines.removed.length !== lines.added.length) return false;
    const signature = line => {
      const match = line.match(/^(\s*(?:-\s*)?uses:\s*)(actions\/[\w-]+)@[a-f0-9]{40}(?:\s+#.*)?$/);
      return match && names.includes(match[2]) ? match[1] + match[2] : null;
    };
    const removed = lines.removed.map(signature);
    const added = lines.added.map(signature);
    return !removed.includes(null) && !added.includes(null) &&
      JSON.stringify(removed.sort()) === JSON.stringify(added.sort());
  });
}

function protectionReady(repository, rules = []) {
  if (!repository.autoMergeAllowed || rules.some(rule => rule.type === 'merge_queue')) return false;
  const protection = repository.ref && repository.ref.branchProtectionRule;
  const contexts = new Set();
  let strict = false;
  if (protection && protection.requiresStatusChecks) {
    strict = protection.requiresStrictStatusChecks;
    protection.requiredStatusCheckContexts.forEach(name => contexts.add(name));
  }
  for (const rule of rules.filter(item => item.type === 'required_status_checks')) {
    strict = strict || rule.parameters.strict_required_status_checks_policy;
    rule.parameters.required_status_checks.forEach(check => contexts.add(check.context));
  }
  return strict && requiredChecks.every(name => contexts.has(name));
}

async function evaluate({ github, context, core, metadata }) {
  const { owner, repo } = context.repo;
  const number = context.payload.pull_request.number;
  const { data: pr } = await github.rest.pulls.get({ owner, repo, pull_number: number });
  if (pr.user.login !== 'dependabot[bot]' || pr.state !== 'open' || pr.draft ||
      pr.base.ref !== 'master' || pr.base.repo.full_name !== `${owner}/${repo}` ||
      !pr.head.repo || pr.head.repo.full_name !== `${owner}/${repo}` ||
      pr.head.sha !== context.payload.pull_request.head.sha) return false;

  const files = await github.paginate(github.rest.pulls.listFiles, {
    owner, repo, pull_number: number, per_page: 100,
  });
  // GitHub's files endpoint is capped; refuse incomplete inspection.
  if (files.length !== pr.changed_files) return false;
  const input = { metadata, files };
  if (metadata.ecosystem === 'bundler') {
    const lockAt = async ref => {
      const { data } = await github.rest.repos.getContent({ owner, repo, path: 'Gemfile.lock', ref });
      if (data.encoding !== 'base64' || !data.content) throw new Error('Missing lockfile contents');
      return Buffer.from(data.content, 'base64').toString('utf8');
    };
    [input.baseLock, input.headLock] = await Promise.all([lockAt(pr.base.sha), lockAt(pr.head.sha)]);
  }
  if (!assessUpdate(input)) return false;

  const result = await github.graphql(`query($owner: String!, $repo: String!) {
    repository(owner: $owner, name: $repo) {
      autoMergeAllowed
      ref(qualifiedName: "refs/heads/master") {
        branchProtectionRule {
          requiresStatusChecks requiresStrictStatusChecks requiredStatusCheckContexts
        }
      }
    }
  }`, { owner, repo });
  const rules = await github.paginate('GET /repos/{owner}/{repo}/rules/branches/{branch}', {
    owner, repo, branch: 'master', per_page: 100,
  });
  if (!protectionReady(result.repository, rules)) {
    core.notice('Auto-merge requires the documented strict branch protection and all required CI checks.');
    return false;
  }
  return true;
}

module.exports = { assessUpdate, protectionReady, evaluate, requiredChecks };
