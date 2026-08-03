#!/usr/bin/env node
/**
 * Unit tests for KDE Plasma 5 cheats.js
 * Run: node tests/test_plasma5_cheats_js.mjs
 */

import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = join(__dirname, '..');
const JS_FILE = join(REPO_ROOT, 'kde-widget-plasma5/DevToolboxPlasmoid/contents/code/cheats.js');

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

// Load pure functions by extracting them from the source
const src = readFileSync(JS_FILE, 'utf-8');

// Evaluate the source in a module context (strip .pragma and .import)
const evalSrc = src
  .replace(/\.pragma library\s*/g, '')
  .replace(/\.import\s+"[^"]+"\s+as\s+\w+/g, '')
  + '\nexport { escapeBashDoubleQuoted, escapePathForBash, bashSafePath, parseIndexOutput, parseFrontMatter, stripFrontMatter, isIconName, GROUP_ICONS, getIndexCommand, getExportMarkdownCommand, getExportCheatCommand, getFzfSearchCommand };';

const mod = await import(`data:text/javascript,${encodeURIComponent(evalSrc)}`);
const {
  escapeBashDoubleQuoted, escapePathForBash, bashSafePath,
  parseIndexOutput, parseFrontMatter, stripFrontMatter, isIconName, GROUP_ICONS,
  getIndexCommand, getExportMarkdownCommand, getExportCheatCommand, getFzfSearchCommand
} = mod;

console.log('\n=== KDE Plasma 5 cheats.js ===\n');

// --- escapeBashDoubleQuoted ---

console.log('escapeBashDoubleQuoted:');

test('leaves plain string untouched', () => {
  assert.equal(escapeBashDoubleQuoted('hello'), 'hello');
});

test('escapes backslashes', () => {
  assert.equal(escapeBashDoubleQuoted('a\\b'), 'a\\\\b');
});

test('escapes double quotes', () => {
  assert.equal(escapeBashDoubleQuoted('a"b'), 'a\\"b');
});

test('escapes dollar signs', () => {
  assert.equal(escapeBashDoubleQuoted('a$b'), 'a\\$b');
});

test('escapes backticks', () => {
  assert.equal(escapeBashDoubleQuoted('a`b'), 'a\\`b');
});

test('escapes multiple special chars', () => {
  assert.equal(escapeBashDoubleQuoted('$HOME/"test"'), '\\$HOME/\\"test\\"');
});

test('handles empty string', () => {
  assert.equal(escapeBashDoubleQuoted(''), '');
});

// --- escapePathForBash ---

console.log('\nescapePathForBash:');

test('restores leading $HOME/ prefix', () => {
  const result = escapePathForBash('$HOME/cheats');
  assert.equal(result, '$HOME/cheats');
});

test('restores leading $HOME/ with spaces', () => {
  const result = escapePathForBash('$HOME/my files');
  assert.equal(result, '$HOME/my files');
});

test('escapes embedded $HOME', () => {
  const result = escapePathForBash('/foo/$HOME/bar');
  assert.equal(result, '/foo/\\$HOME/bar');
});

test('escapes path with double quotes', () => {
  const result = escapePathForBash('/foo/"bar"');
  assert.equal(result, '/foo/\\"bar\\"');
});

test('escapes path with backslashes', () => {
  const result = escapePathForBash('/foo\\bar');
  assert.equal(result, '/foo\\\\bar');
});

test('escapes path with backticks', () => {
  const result = escapePathForBash('/foo`bar');
  assert.equal(result, '/foo\\`bar');
});

test('handles regular absolute path', () => {
  assert.equal(escapePathForBash('/usr/bin'), '/usr/bin');
});

test('handles relative path', () => {
  assert.equal(escapePathForBash('./foo'), './foo');
});

// --- bashSafePath ---

console.log('\nbashSafePath:');

test('handles empty path', () => {
  assert.equal(bashSafePath(''), "''");
});

test('handles null', () => {
  assert.equal(bashSafePath(null), "''");
});

test('expands leading ~/ with $HOME', () => {
  const result = bashSafePath('~/cheats.d');
  assert.equal(result, '"$HOME"/\'cheats.d\'');
});

test('expands leading $HOME/ with $HOME', () => {
  const result = bashSafePath('$HOME/cheats.d');
  assert.equal(result, '"$HOME"/\'cheats.d\'');
});

test('does not expand ~/ in middle of path', () => {
  const result = bashSafePath('/foo/~/bar');
  assert.equal(result, "'/foo/~/bar'");
});

test('handles regular absolute path', () => {
  assert.equal(bashSafePath('/usr/bin'), "'/usr/bin'");
});

test('escapes single quotes in expanded path', () => {
  const result = bashSafePath("~/it's dir");
  assert.equal(result, '"$HOME"/\'it' + "'\\''" + 's dir\'');
});

// --- parseFrontMatter ---

console.log('\nparseFrontMatter:');

test('parses title', () => {
  const result = parseFrontMatter('Title: Git Basics\nSome content');
  assert.equal(result.title, 'Git Basics');
});

test('parses group', () => {
  const result = parseFrontMatter('Group: Dev & Tools\nContent');
  assert.equal(result.group, 'Dev & Tools');
});

test('parses icon', () => {
  const result = parseFrontMatter('Icon: git\nContent');
  assert.equal(result.icon, 'git');
});

test('parses order', () => {
  const result = parseFrontMatter('Order: 10\nContent');
  assert.equal(result.order, 10);
});

test('defaults group to Misc', () => {
  const result = parseFrontMatter('Title: Test\nContent');
  assert.equal(result.group, 'Misc');
});

test('defaults order to 9999', () => {
  const result = parseFrontMatter('Title: Test\nContent');
  assert.equal(result.order, 9999);
});

test('handles case-insensitive keys', () => {
  const result = parseFrontMatter('title: Test\ngroup: Basics');
  assert.equal(result.title, 'Test');
  assert.equal(result.group, 'Basics');
});

test('handles keys with leading whitespace', () => {
  const result = parseFrontMatter('  Title: Indented\n  Group: Test');
  assert.equal(result.title, 'Indented');
  assert.equal(result.group, 'Test');
});

test('handles empty content', () => {
  const result = parseFrontMatter('');
  assert.equal(result.title, '');
  assert.equal(result.group, 'Misc');
  assert.equal(result.order, 9999);
});

// --- stripFrontMatter ---

console.log('\nstripFrontMatter:');

test('removes Title/Group/Icon/Order lines', () => {
  const input = 'Title: Git Basics\nGroup: Dev & Tools\nIcon: git\nOrder: 10\n\nContent here';
  const result = stripFrontMatter(input);
  assert.ok(!result.includes('Title:'));
  assert.ok(!result.includes('Group:'));
  assert.ok(result.includes('Content here'));
});

test('preserves non-metadata content', () => {
  const input = 'Title: Test\n\n# Heading\nSome content';
  const result = stripFrontMatter(input);
  assert.ok(result.includes('# Heading'));
  assert.ok(result.includes('Some content'));
});

test('trims leading empty lines', () => {
  const input = 'Title: Test\n\n\n\nContent';
  const result = stripFrontMatter(input);
  assert.ok(!result.startsWith('\n'));
  assert.ok(result.includes('Content'));
});

test('handles content with no metadata', () => {
  const input = 'Just plain content\nNo metadata here';
  const result = stripFrontMatter(input);
  assert.equal(result, 'Just plain content\nNo metadata here');
});

test('only strips within first 80 lines', () => {
  const lines = Array(85).fill('Line');
  // Put Title at line 81 (index 80) — beyond the 80-line window
  lines[80] = 'Title: Should not be stripped';
  const input = lines.join('\n');
  const result = stripFrontMatter(input);
  // Line 81+ shouldn't be stripped even if they match pattern
  assert.ok(result.includes('Title: Should not be stripped'));
});

// --- isIconName ---

console.log('\nisIconName:');

test('returns false for null/undefined/empty', () => {
  assert.equal(isIconName(null), false);
  assert.equal(isIconName(''), false);
});

test('accepts standard icon names', () => {
  assert.equal(isIconName('git'), true);
  assert.equal(isIconName('network-wired'), true);
  assert.equal(isIconName('go-next'), true);
  assert.equal(isIconName('c++'), true);
});

test('rejects emojis', () => {
  assert.equal(isIconName('🧩'), false);
});

test('rejects strings with spaces', () => {
  assert.equal(isIconName('hello world'), false);
});

// --- parseIndexOutput ---

console.log('\nparseIndexOutput:');

test('parses single entry', () => {
  const input = '/path/to/cheat.md|Git Basics|Dev & Tools|git|10';
  const result = parseIndexOutput(input);
  assert.equal(result.length, 1);
  assert.equal(result[0].name, 'Dev & Tools');
  assert.equal(result[0].cheats.length, 1);
  assert.equal(result[0].cheats[0].title, 'Git Basics');
});

test('groups cheats correctly', () => {
  const input = [
    '/a.md|Alpha|Group1|icon1|1',
    '/b.md|Beta|Group1|icon1|2',
    '/c.md|Gamma|Group2|icon2|1'
  ].join('\n');
  const result = parseIndexOutput(input);
  assert.equal(result.length, 2);
});

test('sorts cheats by order', () => {
  const input = [
    '/b.md|B|G|icon|20',
    '/a.md|A|G|icon|10'
  ].join('\n');
  const result = parseIndexOutput(input);
  assert.equal(result[0].cheats[0].title, 'A');
  assert.equal(result[0].cheats[1].title, 'B');
});

test('deduplicates paths', () => {
  const input = [
    '/a.md|Alpha|G|icon|1',
    '/a.md|Alpha Dup|G|icon|1'
  ].join('\n');
  const result = parseIndexOutput(input);
  assert.equal(result[0].cheats.length, 1);
});

test('skips incomplete lines', () => {
  const input = '/a.md|Alpha|G|icon|1\nbad line';
  const result = parseIndexOutput(input);
  assert.equal(result[0].cheats.length, 1);
});

test('uses GROUP_ICONS fallback', () => {
  const input = '/a.md|Alpha|Network||1';
  const result = parseIndexOutput(input);
  assert.equal(result[0].icon, 'network-wired');
});

test('handles empty input', () => {
  const result = parseIndexOutput('');
  assert.equal(result.length, 0);
});

// --- getIndexCommand ---

console.log('\ngetIndexCommand:');

test('returns a string containing bash', () => {
  const cmd = getIndexCommand('/home/user/cheats', '/tmp/cache');
  assert.ok(typeof cmd === 'string');
  assert.ok(cmd.includes('bash'));
});

test('contains find command', () => {
  const cmd = getIndexCommand('/home/user/cheats', '/tmp/cache');
  assert.ok(cmd.includes('find'));
});

test('contains LC_ALL for UTF-8', () => {
  const cmd = getIndexCommand('/home/user/cheats', '/tmp/cache');
  assert.ok(cmd.includes('LC_ALL'));
});

test('contains metadata extraction', () => {
  const cmd = getIndexCommand('/home/user/cheats', '/tmp/cache');
  assert.ok(cmd.includes('Title'));
  assert.ok(cmd.includes('Group'));
  assert.ok(cmd.includes('Icon'));
  assert.ok(cmd.includes('Order'));
});

test('handles $HOME path', () => {
  const cmd = getIndexCommand('$HOME/cheats', '/tmp/cache');
  assert.ok(cmd.includes('$HOME'));
});

test('uses default debug log when not provided', () => {
  const cmd = getIndexCommand('/home/user/cheats', '/tmp/cache');
  assert.ok(cmd.includes('/tmp/devtoolbox-debug.log'), `Expected command to contain default debug log path, got: ${cmd}`);
});

test('uses provided debug log', () => {
  const cmd = getIndexCommand('/home/user/cheats', '/tmp/cache', '/tmp/my-debug.log');
  assert.ok(cmd.includes('my-debug.log'));
});

// --- getExportMarkdownCommand ---

console.log('\ngetExportMarkdownCommand:');

test('returns a string containing shell command', () => {
  const cmd = getExportMarkdownCommand('/home/user/cheats', '/tmp/out.md');
  assert.ok(typeof cmd === 'string');
  assert.ok(cmd.includes('rm'));
  assert.ok(cmd.includes('echo'));
  assert.ok(cmd.includes('find'));
});

test('contains output file', () => {
  const cmd = getExportMarkdownCommand('/home/user/cheats', '/tmp/out.md');
  assert.ok(cmd.includes('out.md'));
});

test('contains Dev Toolbox header', () => {
  const cmd = getExportMarkdownCommand('/home/user/cheats', '/tmp/out.md');
  assert.ok(cmd.includes('Dev Toolbox Cheatsheet'));
});

test('contains sed for stripping metadata', () => {
  const cmd = getExportMarkdownCommand('/home/user/cheats', '/tmp/out.md');
  assert.ok(cmd.includes('sed'));
  assert.ok(cmd.includes('Title'));
});

// --- getExportCheatCommand ---

console.log('\ngetExportCheatCommand:');

test('returns a string containing bash', () => {
  const cmd = getExportCheatCommand('/home/user/cheats/test.md', '/tmp/out.md');
  assert.ok(typeof cmd === 'string');
  assert.ok(cmd.includes('bash'));
});

test('contains sed to strip front matter', () => {
  const cmd = getExportCheatCommand('/home/user/cheats/test.md', '/tmp/out.md');
  assert.ok(cmd.includes('sed'));
  // The regex pattern uses [Tt]itle which doesn't contain literal 'Title'
  assert.ok(cmd.includes('[Tt]itle') || cmd.includes('Title'));
});

test('contains notify-send', () => {
  const cmd = getExportCheatCommand('/home/user/cheats/test.md', '/tmp/out.md');
  assert.ok(cmd.includes('notify-send'));
});

// --- getFzfSearchCommand ---

console.log('\ngetFzfSearchCommand:');

test('returns a string containing bash', () => {
  const cmd = getFzfSearchCommand('/home/user/cheats');
  assert.ok(typeof cmd === 'string');
  assert.ok(cmd.includes('bash'));
});

test('contains fzf command check', () => {
  const cmd = getFzfSearchCommand('/home/user/cheats');
  assert.ok(cmd.includes('fzf'));
});

test('contains grep for searching', () => {
  const cmd = getFzfSearchCommand('/home/user/cheats');
  assert.ok(cmd.includes('grep'));
});

test('contains preview window', () => {
  const cmd = getFzfSearchCommand('/home/user/cheats');
  assert.ok(cmd.includes('preview'));
});

test('contains editor logic', () => {
  const cmd = getFzfSearchCommand('/home/user/cheats');
  assert.ok(cmd.includes('EDITOR'));
});

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
