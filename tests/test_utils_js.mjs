#!/usr/bin/env node
/**
 * Unit tests for KDE Plasma 5/6 utils.js (pure functions only)
 * Run: node tests/test_utils_js.mjs
 *
 * Note: fileExists, readFile, writeFile, executeCommand require QML runtime
 * and cannot be tested in Node.js. Only trim() and formatDate() are tested.
 */

import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = join(__dirname, '..');

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  \x1b[32m✓\x1b[0m ${name}`);
    passed++;
  } catch (e) {
    console.log(`  \x1b[31m✗\x1b[0m ${name}`);
    console.log(`    ${e.message}`);
    failed++;
  }
}

// Load both Plasma 5 and 6 utils.js (they're identical)
for (const version of ['plasma5', 'plasma6']) {
  const JS_FILE = join(REPO_ROOT, `kde-widget-${version}/DevToolboxPlasmoid/contents/code/utils.js`);
  const src = readFileSync(JS_FILE, 'utf-8');

  const evalSrc = src
    .replace(/\.pragma library\s*/g, '')
    .replace(/\.import\s+"[^"]+"\s+as\s+\w+/g, '')
    + '\nexport { trim, formatDate };';

  const mod = await import(`data:text/javascript,${encodeURIComponent(evalSrc)}`);
  const { trim, formatDate } = mod;

  console.log(`\n=== KDE ${version} utils.js ===\n`);

  // --- trim ---

  console.log('trim:');

  test(`[${version}] trims leading spaces`, () => {
    assert.equal(trim('  hello'), 'hello');
  });

  test(`[${version}] trims trailing spaces`, () => {
    assert.equal(trim('hello  '), 'hello');
  });

  test(`[${version}] trims both sides`, () => {
    assert.equal(trim('  hello  '), 'hello');
  });

  test(`[${version}] trims tabs`, () => {
    assert.equal(trim('\thello\t'), 'hello');
  });

  test(`[${version}] trims newlines`, () => {
    assert.equal(trim('\nhello\n'), 'hello');
  });

  test(`[${version}] does not trim inner spaces`, () => {
    assert.equal(trim('hello world'), 'hello world');
  });

  test(`[${version}] handles empty string`, () => {
    assert.equal(trim(''), '');
  });

  test(`[${version}] handles whitespace-only string`, () => {
    assert.equal(trim('   '), '');
  });

  // --- formatDate ---

  console.log('\nformatDate:');

  test(`[${version}] formats date correctly`, () => {
    const d = new Date(2025, 0, 15, 14, 30); // Jan 15, 2025 14:30
    assert.equal(formatDate(d), '2025-01-15_14-30');
  });

  test(`[${version}] pads single-digit month`, () => {
    const d = new Date(2025, 2, 5, 9, 5); // Mar 5, 2025 09:05
    assert.equal(formatDate(d), '2025-03-05_09-05');
  });

  test(`[${version}] pads single-digit day`, () => {
    const d = new Date(2025, 11, 1, 0, 0); // Dec 1, 2025 00:00
    assert.equal(formatDate(d), '2025-12-01_00-00');
  });

  test(`[${version}] handles midnight`, () => {
    const d = new Date(2025, 5, 15, 0, 0);
    assert.equal(formatDate(d), '2025-06-15_00-00');
  });

  test(`[${version}] handles end of day`, () => {
    const d = new Date(2025, 11, 31, 23, 59);
    assert.equal(formatDate(d), '2025-12-31_23-59');
  });
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
