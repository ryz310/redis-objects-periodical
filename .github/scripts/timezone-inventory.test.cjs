'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const { mkdtempSync, rmSync, writeFileSync } = require('node:fs');
const { tmpdir } = require('node:os');
const { join } = require('node:path');
const { expectedDescriptions, validateInventory } = require('./timezone-inventory.cjs');

const complete = () => ({
  examples: expectedDescriptions.map(full_description => ({ full_description, status: 'passed' })),
});

test('accepts the complete passed inventory independently of report order', () => {
  const report = complete();
  report.examples.reverse();
  assert.equal(validateInventory(report), expectedDescriptions.length);
});

for (const [dimension, match] of [
  ['Tokyo zone', 'with Time.zone = "Asia/Tokyo"'],
  ['unset zone', 'with Time.zone = nil'],
  ['year/month boundary', 'when crossing the year and month boundary'],
  ['week boundary', 'when crossing the week boundary'],
  ['period', 'persists the weekly '],
  ['type', ' hash_key in the selected timezone'],
]) {
  test(`rejects a missing ${dimension}`, () => {
    const report = complete();
    report.examples = report.examples.filter(example => !example.full_description.includes(match));
    assert.throws(() => validateInventory(report), /Missing example/);
  });
}

test('rejects an empty selection even when RSpec reports zero failures', () => {
  assert.throws(() => validateInventory({ examples: [], summary: { failure_count: 0 } }), /Missing example/);
});

test('rejects a single missing combination even if a duplicate preserves the total count', () => {
  const report = complete();
  report.examples[0] = report.examples[1];
  assert.throws(() => validateInventory(report), /Duplicate example[\s\S]*Missing example/);
});

for (const status of ['pending', 'failed', 'skipped', undefined]) {
  test(`rejects an intended example with status ${status}`, () => {
    const report = complete();
    report.examples[0].status = status;
    assert.throws(() => validateInventory(report), /Example/);
  });
}

test('rejects unexpected examples rather than allowing substitutions', () => {
  const report = complete();
  report.examples[0].full_description = 'unrelated passed example';
  assert.throws(() => validateInventory(report), /Unexpected example[\s\S]*Missing example/);
});

test('rejects a malformed report', () => {
  assert.throws(() => validateInventory({}), /Missing RSpec examples array/);
});

test('CLI fails closed for missing, invalid, empty and pending reports, and accepts complete output', () => {
  const directory = mkdtempSync(join(tmpdir(), 'timezone-inventory-'));
  const filename = join(directory, 'report.json');
  const script = join(__dirname, 'timezone-inventory.cjs');
  const run = () => spawnSync(process.execPath, [script, filename], { encoding: 'utf8' });
  try {
    assert.equal(run().status, 1);
    for (const contents of ['{', JSON.stringify({ examples: [] }), JSON.stringify({
      examples: complete().examples.map(example => ({ ...example, status: 'pending' })),
    })]) {
      writeFileSync(filename, contents);
      const result = run();
      assert.equal(result.status, 1);
      assert.match(result.stderr, /Timezone inventory validation failed/);
    }
    writeFileSync(filename, JSON.stringify(complete()));
    const result = run();
    assert.equal(result.status, 0);
    assert.match(result.stdout, /Verified .* passed timezone integration examples/);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
