// tests/test_qml_toc_format.test.mjs
//
// Regression tests for the `applyTocFormatNow()` JavaScript function
// embedded in the KDE Plasma widget config QML files
// (kde-widget-plasma5 / kde-widget-plasma6 DevToolboxPlasmoid
// configGeneral.qml). This change fixed a shell-injection vulnerability:
// `cfg_cheatsDir` (a user-controlled directory path) is now single-quote
// shell-escaped before being embedded into a generated shell command
// string, instead of being interpolated verbatim.
//
// The function is extracted directly from the QML source (via regex) and
// evaluated with `new Function(...)` so the test always exercises the
// real, current implementation rather than a hand-copied duplicate.
//
// Run directly:
//   node --test tests/test_qml_toc_format.test.mjs

import test from 'node:test';
import assert from 'node:assert/strict';
import { execSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..');

const QML_FILES = [
  path.join(REPO_ROOT, 'kde-widget-plasma5', 'DevToolboxPlasmoid', 'contents', 'ui', 'configGeneral.qml'),
  path.join(REPO_ROOT, 'kde-widget-plasma6', 'DevToolboxPlasmoid', 'contents', 'ui', 'configGeneral.qml'),
];

function extractApplyTocFormatNow(qmlSource) {
  const match = qmlSource.match(/function applyTocFormatNow\(\)\s*\{([\s\S]*?)\n\s{4}\}/);
  if (!match) {
    throw new Error('Could not locate applyTocFormatNow() in QML source');
  }
  return match[1];
}

function buildFn(qmlSource) {
  const body = extractApplyTocFormatNow(qmlSource);
  // eslint-disable-next-line no-new-func
  return new Function('cfg_cheatsDir', 'cfg_tocFormat', 'tocApplyStatus', 'tocFormatApplier', body);
}

function callApplyTocFormatNow(qmlSource, cheatsDir, tocFormat) {
  const tocApplyStatus = { text: '' };
  let capturedCommand = null;
  const tocFormatApplier = {
    connectSource(cmd) {
      capturedCommand = cmd;
    },
  };
  const fn = buildFn(qmlSource);
  fn(cheatsDir, tocFormat, tocApplyStatus, tocFormatApplier);
  return { capturedCommand, tocApplyStatus };
}

for (const qmlPath of QML_FILES) {
  const label = path.relative(REPO_ROOT, qmlPath);
  const qmlSource = fs.readFileSync(qmlPath, 'utf8');

  test(`${label}: sets a "applying" status message immediately`, () => {
    const { tocApplyStatus } = callApplyTocFormatNow(qmlSource, '~/cheats.d', 'obsidian');
    assert.match(tocApplyStatus.text, /Applying/);
  });

  test(`${label}: home-relative path is quoted and prefixed with $HOME`, () => {
    const { capturedCommand } = callApplyTocFormatNow(qmlSource, '~/cheats.d', 'obsidian');
    assert.match(capturedCommand, /"\$HOME"\/'cheats\.d'/);
  });

  test(`${label}: absolute path is single-quoted without a $HOME prefix`, () => {
    const { capturedCommand } = callApplyTocFormatNow(qmlSource, '/tmp/mycheats', 'obsidian');
    assert.match(capturedCommand, /--dir '\/tmp\/mycheats'/);
    assert.doesNotMatch(capturedCommand, /\$HOME"\/'\/tmp\/mycheats'/);
  });

  test(`${label}: unrecognized tocFormat falls back to obsidian`, () => {
    const { capturedCommand } = callApplyTocFormatNow(qmlSource, '~/cheats.d', 'not-a-real-format; rm -rf /');
    assert.match(capturedCommand, /--style 'obsidian'/);
    assert.doesNotMatch(capturedCommand, /rm -rf/);
  });

  test(`${label}: github format is passed through verbatim`, () => {
    const { capturedCommand } = callApplyTocFormatNow(qmlSource, '~/cheats.d', 'github');
    assert.match(capturedCommand, /--style 'github'/);
  });

  test(`${label}: embeds the write-config command and the search+run command joined by &&`, () => {
    const { capturedCommand } = callApplyTocFormatNow(qmlSource, '~/cheats.d', 'obsidian');
    assert.match(capturedCommand, /toc_format\.conf/);
    assert.match(capturedCommand, /manage-tocs\.py/);
    assert.match(capturedCommand, / && /);
  });

  test(`${label}: shell-injection attempt via cfg_cheatsDir is neutralized (no command execution)`, () => {
    const tmpHome = fs.mkdtempSync(path.join(os.tmpdir(), 'qml-toc-inject-'));
    const marker = path.join(tmpHome, 'PWNED_MARKER');
    try {
      const maliciousDir = `cheats.d'; touch ${marker}; echo '`;
      const { capturedCommand } = callApplyTocFormatNow(qmlSource, `~/${maliciousDir}`, 'obsidian');

      // Stub python3 and provide a fake manage-tocs.py so the generated
      // command runs to completion (exit 0) instead of bailing out early
      // via its own "manage-tocs.py not found" guard — we want to prove
      // the injected segment never executes even when the rest of the
      // pipeline succeeds.
      const binDir = path.join(tmpHome, 'bin');
      fs.mkdirSync(binDir);
      const stubPython3 = path.join(binDir, 'python3');
      fs.writeFileSync(stubPython3, '#!/usr/bin/env bash\nexit 0\n');
      fs.chmodSync(stubPython3, 0o755);
      const localShare = path.join(tmpHome, '.local', 'share', 'devtoolbox-cheats', 'tools');
      fs.mkdirSync(localShare, { recursive: true });
      fs.writeFileSync(path.join(localShare, 'manage-tocs.py'), '# stub\n');

      try {
        execSync(capturedCommand, {
          shell: '/bin/bash',
          env: { ...process.env, HOME: tmpHome, PATH: `${binDir}:${process.env.PATH}` },
          timeout: 10000,
          stdio: 'pipe',
        });
      } catch (err) {
        // Expected to fail, we just want to ensure it didn't create the marker
      }

      assert.equal(
        fs.existsSync(marker),
        false,
        'injected command executed — cfg_cheatsDir was not safely shell-escaped'
      );
    } finally {
      fs.rmSync(tmpHome, { recursive: true, force: true });
    }
  });

  test(`${label}: benign path with a literal single quote is preserved through execution`, () => {
    const tmpHome = fs.mkdtempSync(path.join(os.tmpdir(), 'qml-toc-quote-'));
    try {
      const { capturedCommand } = callApplyTocFormatNow(qmlSource, "~/it's-a-dir", 'obsidian');

      const binDir = path.join(tmpHome, 'bin');
      fs.mkdirSync(binDir);
      const stubPython3 = path.join(binDir, 'python3');
      // Record the --dir argument it was invoked with.
      fs.writeFileSync(
        stubPython3,
        '#!/usr/bin/env bash\nprintf \'%s\\n\' "$@" > "$RECORDED_ARGS_FILE"\nexit 0\n'
      );
      fs.chmodSync(stubPython3, 0o755);
      // Provide a fake manage-tocs.py so the find-based search succeeds.
      const localShare = path.join(tmpHome, '.local', 'share', 'devtoolbox-cheats', 'tools');
      fs.mkdirSync(localShare, { recursive: true });
      fs.writeFileSync(path.join(localShare, 'manage-tocs.py'), '# stub\n');

      const recordedArgsFile = path.join(tmpHome, 'args.log');
      execSync(capturedCommand, {
        shell: '/bin/bash',
        env: {
          ...process.env,
          HOME: tmpHome,
          PATH: `${binDir}:${process.env.PATH}`,
          RECORDED_ARGS_FILE: recordedArgsFile,
        },
        timeout: 10000,
        stdio: 'pipe',
      });

      const recordedArgs = fs.readFileSync(recordedArgsFile, 'utf8');
      assert.match(recordedArgs, /it's-a-dir/, 'the literal single quote in the path was lost');
    } finally {
      fs.rmSync(tmpHome, { recursive: true, force: true });
    }
  });
}