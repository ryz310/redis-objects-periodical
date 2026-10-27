'use strict';

const { readFileSync } = require('node:fs');

// Independent execution contract for the integration fixtures. Update this definition
// when deliberately adding/removing fixture dimensions; do not derive it from the report.
const inventory = {
  boundaries: ['year and month boundary', 'week boundary'],
  zones: ['"Asia/Tokyo"', 'nil'],
  periods: ['annual', 'monthly', 'weekly', 'daily', 'hourly', 'minutely'],
  types: ['counter', 'value', 'set', 'hash_key'],
};
const expectedDescriptions = inventory.boundaries.flatMap(boundary =>
  inventory.zones.flatMap(zone =>
    inventory.periods.flatMap(period =>
      inventory.types.map(type =>
        `Redis::RecurringAtIntervals when crossing the ${boundary} with Time.zone = ${zone} persists the ${period} ${type} in the selected timezone`))));

function validateInventory(report) {
  if (!Array.isArray(report.examples)) throw new Error('Missing RSpec examples array');
  const expected = new Set(expectedDescriptions);
  const seen = new Set();
  const problems = [];
  for (const example of report.examples) {
    const name = example.full_description;
    if (!expected.has(name)) problems.push(`Unexpected example: ${name}`);
    if (seen.has(name)) problems.push(`Duplicate example: ${name}`);
    if (example.status !== 'passed') problems.push(`Example ${example.status}: ${name}`);
    seen.add(name);
  }
  for (const name of expected) {
    if (!seen.has(name)) problems.push(`Missing example: ${name}`);
  }
  if (problems.length) throw new Error(problems.join('\n'));
  return seen.size;
}

if (require.main === module) {
  try {
    const count = validateInventory(JSON.parse(readFileSync(process.argv[2], 'utf8')));
    console.log(`Verified ${count} passed timezone integration examples`);
  } catch (error) {
    console.error(`Timezone inventory validation failed: ${error.message}`);
    process.exitCode = 1;
  }
}

module.exports = { expectedDescriptions, validateInventory };
