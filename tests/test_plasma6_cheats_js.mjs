#!/usr/bin/env node
/**
 * Unit tests for KDE Plasma 6 cheats.js
 * Run: node tests/test_plasma6_cheats_js.mjs
 */

import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = join(__dirname, '..');
const JS_FILE = join(REPO_ROOT, 'kde-widget-plasma6/DevToolboxPlasmoid/contents/code/cheats.js');

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
  + '\nexport { escapeShell, bashSafePath, plasmaShield, parseIndexOutput, isIconName, GROUP_ICONS, getExportMarkdownCommand, getExportCheatCommand, getFzfSearchCommand };';

const mod = await import(`data:text/javascript,${encodeURIComponent(evalSrc)}`);
const {
  escapeShell, bashSafePath, plasmaShield, parseIndexOutput, isIconName, GROUP_ICONS,
  getExportMarkdownCommand, getExportCheatCommand, getFzfSearchCommand
} = mod;

console.log('\n=== KDE Plasma 6 cheats.js ===\n');

// --- escapeShell ---

console.log('escapeShell:');

test('wraps plain string in single quotes', () => {
  assert.equal(escapeShell('hello'), "'hello'");
});

test('escapes embedded single quotes', () => {
  assert.equal(escapeShell("it's"), "'it'\\''s'");
});

test('handles empty string', () => {
  assert.equal(escapeShell(''), "''");
});

test('handles null/undefined', () => {
  assert.equal(escapeShell(null), "''");
  assert.equal(escapeShell(undefined), "''");
});

test('handles path with spaces', () => {
  assert.equal(escapeShell('/home/user/my file.txt'), "'/home/user/my file.txt'");
});

test('handles path with single quotes and spaces', () => {
  const result = escapeShell("/home/user/it's a file.txt");
  assert.ok(result.startsWith("'"), 'starts with single quote');
  assert.ok(result.endsWith("'"), 'ends with single quote');
  assert.ok(result.includes("'\\''"), 'contains escaped single quote');
});

test('handles special characters', () => {
  assert.equal(escapeShell('a;b&c'), "'a;b&c'");
});

test('handles $ signs', () => {
  assert.equal(escapeShell('$HOME'), "'$HOME'");
});

test('handles backticks', () => {
  assert.equal(escapeShell('`cmd`'), "'`cmd`'");
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

test('handles relative path', () => {
  assert.equal(bashSafePath('./foo'), "'./foo'");
});

test('escapes single quotes in expanded path', () => {
  const result = bashSafePath("~/it's dir");
  assert.equal(result, '"$HOME"/\'it' + "'\\''" + 's dir\'');
});

test('handles $HOME/ with path containing spaces', () => {
  const result = bashSafePath('$HOME/my files');
  assert.equal(result, '"$HOME"/\'my files\'');
});

// --- plasmaShield ---

console.log('\nplasmaShield:');

test('returns empty for null/undefined', () => {
  assert.equal(plasmaShield(null), '');
  assert.equal(plasmaShield(undefined), '');
});

test('returns empty for empty string', () => {
  assert.equal(plasmaShield(''), '');
});

test('leaves alphanumeric and spaces untouched', () => {
  assert.equal(plasmaShield('hello world 123'), 'hello world 123');
});

test('escapes special characters', () => {
  assert.equal(plasmaShield('a$b'), 'a\\$b');
  assert.equal(plasmaShield('a"b'), 'a\\"b');
  assert.equal(plasmaShield("a'b"), "a\\'b");
});

test('escapes parentheses', () => {
  assert.equal(plasmaShield('echo (foo)'), 'echo \\(foo\\)');
});

test('escapes pipe character', () => {
  assert.equal(plasmaShield('a|b'), 'a\\|b');
});

test('escapes ampersand', () => {
  assert.equal(plasmaShield('a&b'), 'a\\&b');
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
  assert.equal(isIconName('zoom-in+'), true);
  assert.equal(isIconName('utilities-system-monitor'), true);
});

test('accepts icon names with dots', () => {
  assert.equal(isIconName('text.x-preview'), true);
});

test('rejects emojis', () => {
  assert.equal(isIconName('🧩'), false);
});

test('rejects paths', () => {
  assert.equal(isIconName('/usr/share/icon.png'), false);
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
  assert.equal(result[0].cheats[0].path, '/path/to/cheat.md');
  assert.equal(result[0].cheats[0].title, 'Git Basics');
  assert.equal(result[0].cheats[0].order, 10);
});

test('groups cheats correctly', () => {
  const input = [
    '/a.md|Alpha|Group1|icon1|1',
    '/b.md|Beta|Group1|icon1|2',
    '/c.md|Gamma|Group2|icon2|1'
  ].join('\n');
  const result = parseIndexOutput(input);
  assert.equal(result.length, 2);
  assert.equal(result[0].name, 'Group1');
  assert.equal(result[0].cheats.length, 2);
  assert.equal(result[1].name, 'Group2');
  assert.equal(result[1].cheats.length, 1);
});

test('sorts cheats by order within groups', () => {
  const input = [
    '/b.md|B|G|icon|20',
    '/a.md|A|G|icon|10',
    '/c.md|C|G|icon|30'
  ].join('\n');
  const result = parseIndexOutput(input);
  assert.equal(result[0].cheats[0].title, 'A');
  assert.equal(result[0].cheats[1].title, 'B');
  assert.equal(result[0].cheats[2].title, 'C');
});

test('deduplicates paths', () => {
  const input = [
    '/a.md|Alpha|G|icon|1',
    '/a.md|Alpha Dup|G|icon|1'
  ].join('\n');
  const result = parseIndexOutput(input);
  assert.equal(result[0].cheats.length, 1);
});

test('skips lines with fewer than 5 parts', () => {
  const input = [
    '/a.md|Alpha|G|icon|1',
    'incomplete|line',
    '/b.md|Beta|G|icon|2'
  ].join('\n');
  const result = parseIndexOutput(input);
  assert.equal(result[0].cheats.length, 2);
});

test('uses GROUP_ICONS as fallback for missing icon', () => {
  const input = '/a.md|Alpha|Network||1';
  const result = parseIndexOutput(input);
  assert.equal(result[0].icon, 'network-wired');
});

test('uses emoji fallback for unknown group with no icon', () => {
  const input = '/a.md|Alpha|UnknownGroup||1';
  const result = parseIndexOutput(input);
  assert.equal(result[0].icon, '🧩');
});

test('handles empty input', () => {
  const result = parseIndexOutput('');
  assert.equal(result.length, 0);
});

test('groups are sorted alphabetically', () => {
  const input = [
    '/c.md|C|Zebra|icon|1',
    '/a.md|A|Alpha|icon|1',
    '/m.md|M|Middle|icon|1'
  ].join('\n');
  const result = parseIndexOutput(input);
  assert.equal(result[0].name, 'Alpha');
  assert.equal(result[1].name, 'Middle');
  assert.equal(result[2].name, 'Zebra');
});

test('defaults order to 9999 for non-numeric', () => {
  const input = '/a.md|Alpha|G|icon|abc';
  const result = parseIndexOutput(input);
  assert.equal(result[0].cheats[0].order, 9999);
});

test('defaults order to 9999 for empty order', () => {
  const input = '/a.md|Alpha|G|icon|';
  const result = parseIndexOutput(input);
  assert.equal(result[0].cheats[0].order, 9999);
});

// --- getExportMarkdownCommand ---

console.log('\ngetExportMarkdownCommand:');

test('returns a string containing bash', () => {
  const cmd = getExportMarkdownCommand('/home/user/cheats', '/tmp/out.md');
  assert.ok(typeof cmd === 'string');
  assert.ok(cmd.includes('bash'));
});

test('contains find command for cheats dir', () => {
  const cmd = getExportMarkdownCommand('/home/user/cheats', '/tmp/out.md');
  assert.ok(cmd.includes('find'));
});

test('contains output file', () => {
  const cmd = getExportMarkdownCommand('/home/user/cheats', '/tmp/out.md');
  // plasmaShield escapes dots, so check for the filename with or without escaping
  assert.ok(cmd.includes('out.md') || cmd.includes('out\\.md'));
});

test('contains header text', () => {
  const cmd = getExportMarkdownCommand('/home/user/cheats', '/tmp/out.md');
  assert.ok(cmd.includes('Dev Toolbox Cheatsheet'));
});

test('handles paths with $HOME', () => {
  const cmd = getExportMarkdownCommand('$HOME/cheats', '$HOME/out.md');
  assert.ok(cmd.includes('$HOME'));
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
  // plasmaShield escapes special chars in regex patterns
  assert.ok(cmd.includes('sed'));
  assert.ok(cmd.includes('Title') || cmd.includes('\\[Tt\\]itle') || cmd.includes('[Tt]itle'));
  assert.ok(cmd.includes('Group') || cmd.includes('\\[Gg\\]roup') || cmd.includes('[Gg]roup'));
});

test('contains notify-send', () => {
  const cmd = getExportCheatCommand('/home/user/cheats/test.md', '/tmp/out.md');
  assert.ok(cmd.includes('notify'));
});

test('contains input file path', () => {
  const cmd = getExportCheatCommand('/home/user/cheats/test.md', '/tmp/out.md');
  // plasmaShield escapes dots and slashes
  assert.ok(cmd.includes('test.md') || cmd.includes('test\\.md'));
});

// --- getFzfSearchCommand ---

console.log('\ngetFzfSearchCommand:');

test('returns a string containing bash', () => {
  const cmd = getFzfSearchCommand('/home/user/cheats', 'code');
  assert.ok(typeof cmd === 'string');
  assert.ok(cmd.includes('bash'));
});

test('contains fzf command check', () => {
  const cmd = getFzfSearchCommand('/home/user/cheats', 'code');
  assert.ok(cmd.includes('fzf'));
});

test('contains grep for searching', () => {
  const cmd = getFzfSearchCommand('/home/user/cheats', 'code');
  assert.ok(cmd.includes('grep'));
});

test('contains editor in command', () => {
  const cmd = getFzfSearchCommand('/home/user/cheats', 'nano');
  assert.ok(cmd.includes('nano'));
});

test('defaults editor to code', () => {
  const cmd = getFzfSearchCommand('/home/user/cheats');
  assert.ok(cmd.includes('code'));
});

test('contains preview window', () => {
  const cmd = getFzfSearchCommand('/home/user/cheats', 'code');
  assert.ok(cmd.includes('preview'));
});

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
