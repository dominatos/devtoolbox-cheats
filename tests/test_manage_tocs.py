#!/usr/bin/env python3
"""Unit tests for tools/manage-tocs.py.

This module has a hyphen in its filename so it is loaded dynamically via
importlib rather than a normal `import`. Run with:

    python3 -m unittest tests/test_manage_tocs.py -v

or simply:

    python3 tests/test_manage_tocs.py
"""

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MODULE_PATH = REPO_ROOT / "tools" / "manage-tocs.py"


def _load_module():
    """
    Load the TOC management module from its configured file path.
    
    Returns:
        module: The dynamically loaded module.
    """
    spec = importlib.util.spec_from_file_location("manage_tocs", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


manage_tocs = _load_module()


class HeadingToGithubSlugTests(unittest.TestCase):
    def test_basic_words(self):
        self.assertEqual(manage_tocs.heading_to_github_slug("Hello World"), "hello-world")

    def test_ampersand_and_punctuation_removed(self):
        self.assertEqual(manage_tocs.heading_to_github_slug("Install & Configure"), "install-configure")

    def test_special_characters_stripped(self):
        self.assertEqual(
            manage_tocs.heading_to_github_slug("Special!@#$%^&*()Chars"), "specialchars"
        )

    def test_emoji_removed(self):
        self.assertEqual(
            manage_tocs.heading_to_github_slug("\U0001F500 Basic Substitution"),
            "basic-substitution",
        )

    def test_multiple_and_leading_trailing_spaces_collapsed(self):
        self.assertEqual(
            manage_tocs.heading_to_github_slug("  Multiple   Spaces  "), "multiple-spaces"
        )

    def test_existing_hyphens_preserved(self):
        self.assertEqual(
            manage_tocs.heading_to_github_slug("Already-Hyphenated Text"),
            "already-hyphenated-text",
        )

    def test_uppercase_lowercased(self):
        self.assertEqual(
            manage_tocs.heading_to_github_slug("CamelCase AND UPPER"), "camelcase-and-upper"
        )

    def test_numbers_preserved(self):
        self.assertEqual(manage_tocs.heading_to_github_slug("Numbers 123 Test"), "numbers-123-test")

    def test_empty_string(self):
        self.assertEqual(manage_tocs.heading_to_github_slug(""), "")


class CleanHeaderTests(unittest.TestCase):
    def test_plain_header_unchanged(self):
        line, text = manage_tocs.clean_header("## Basic Substitution")
        self.assertEqual(line, "## Basic Substitution")
        self.assertEqual(text, "Basic Substitution")

    def test_cyrillic_translation_suffix_removed(self):
        line, text = manage_tocs.clean_header("## \U0001F500 Basic Substitution / \u0411\u0430\u0437\u043e\u0432\u0430\u044f \u0437\u0430\u043c\u0435\u043d\u0430")
        self.assertEqual(line, "## \U0001F500 Basic Substitution")
        self.assertEqual(text, "\U0001F500 Basic Substitution")

    def test_non_cyrillic_slash_segment_is_kept(self):
        # This is the key behavior change vs. the old implementation:
        # only strip the " / " suffix when it is Cyrillic, otherwise keep
        # the whole heading (e.g. "Network / Firewall").
        line, text = manage_tocs.clean_header("## Section / English Only")
        self.assertEqual(line, "## Section / English Only")
        self.assertEqual(text, "Section / English Only")

    def test_only_first_slash_segment_considered(self):
        line, text = manage_tocs.clean_header(
            "## Mixed / \u0427\u0430\u0441\u0442\u044c \u043d\u0430 \u0440\u0443\u0441\u0441\u043a\u043e\u043c / another"
        )
        self.assertEqual(line, "## Mixed")
        self.assertEqual(text, "Mixed")

    def test_extra_whitespace_after_hashes_stripped(self):
        line, text = manage_tocs.clean_header("##   Extra Spaces Header")
        self.assertEqual(line, "## Extra Spaces Header")
        self.assertEqual(text, "Extra Spaces Header")

    def test_no_space_after_hashes_is_not_matched(self):
        # Regex requires at least one whitespace character after '##';
        # this documents the current (imperfect) behavior.
        line, text = manage_tocs.clean_header("##NoSpace")
        self.assertEqual(line, "## ##NoSpace")
        self.assertEqual(text, "##NoSpace")


class ProcessFileTests(unittest.TestCase):
    def setUp(self):
        self.tmpdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmpdir.cleanup)
        self.path = Path(self.tmpdir.name) / "test.md"

    def _write(self, content: str) -> None:
        """Write text content to the configured file path using UTF-8 encoding."""
        self.path.write_text(content, encoding="utf-8")

    def test_rebuilds_obsidian_toc(self):
        self._write(
            "# Title\n\n"
            "## Table of Contents\n\n"
            "- old link\n\n"
            "---\n\n"
            "## First Section\n\n"
            "Some text.\n\n"
            "## Second Section\n\n"
            "More text.\n"
        )
        changed = manage_tocs.process_file(self.path, "obsidian")
        self.assertEqual(changed, 1)
        out = self.path.read_text(encoding="utf-8")
        self.assertIn("- [First Section](#First%20Section)", out)
        self.assertIn("- [Second Section](#Second%20Section)", out)
        self.assertNotIn("old link", out)

    def test_rebuilds_github_toc(self):
        self._write(
            "# Title\n\n"
            "## Table of Contents\n\n"
            "- old link\n\n"
            "---\n\n"
            "## First Section\n\n"
            "text\n"
        )
        changed = manage_tocs.process_file(self.path, "github")
        self.assertEqual(changed, 1)
        out = self.path.read_text(encoding="utf-8")
        self.assertIn("- [First Section](#first-section)", out)

    def test_headings_inside_code_fences_are_ignored(self):
        self._write(
            "# Title\n\n"
            "## Table of Contents\n\n"
            "- old\n\n"
            "---\n\n"
            "## Real Section\n\n"
            "```bash\n"
            "## this is not a heading, inside fence\n"
            "```\n\n"
            "## Second Section\n"
        )
        changed = manage_tocs.process_file(self.path, "obsidian")
        self.assertEqual(changed, 1)
        out = self.path.read_text(encoding="utf-8")
        # The fenced "heading" must not appear in the rebuilt TOC.
        self.assertNotIn("this-is-not-a-heading", out.lower())
        self.assertIn("- [Real Section](#Real%20Section)", out)
        self.assertIn("- [Second Section](#Second%20Section)", out)
        # The fenced content itself is left untouched.
        self.assertIn("## this is not a heading, inside fence", out)

    def test_header_cleaned_even_without_toc(self):
        self._write(
            "# Title\n\nNo TOC here.\n\n## Section / \u0421\u0435\u043a\u0446\u0438\u044f\n\ntext\n"
        )
        changed = manage_tocs.process_file(self.path, "obsidian")
        self.assertEqual(changed, 1)
        out = self.path.read_text(encoding="utf-8")
        self.assertIn("## Section\n", out)
        self.assertNotIn("\u0421\u0435\u043a\u0446\u0438\u044f", out)

    def test_no_changes_needed_returns_false(self):
        self._write("# Title\n\nNo TOC here.\n\n## Only Section\n\ntext\n")
        changed = manage_tocs.process_file(self.path, "obsidian")
        self.assertEqual(changed, 0)

    def test_idempotent_second_run_returns_false(self):
        self._write(
            "# Title\n\n## Table of Contents\n\n- old\n\n---\n\n## Section One\n\ntext\n"
        )
        first = manage_tocs.process_file(self.path, "obsidian")
        second = manage_tocs.process_file(self.path, "obsidian")
        self.assertEqual(first, 1)
        self.assertEqual(second, 0)

    def test_missing_file_returns_minus_one_without_raising(self):
        missing = Path(self.tmpdir.name) / "does-not-exist.md"
        result = manage_tocs.process_file(missing, "obsidian")
        self.assertEqual(result, -1)

    def test_unrecognized_style_falls_back_to_obsidian_format(self):
        self._write(
            "# Title\n\n## Table of Contents\n\n- old\n\n---\n\n## A Section\n\ntext\n"
        )
        manage_tocs.process_file(self.path, "unknown-style")
        out = self.path.read_text(encoding="utf-8")
        self.assertIn("- [A Section](#A%20Section)", out)


class MainCliTests(unittest.TestCase):
    def _run_cli(self, *args):
        """Run the management CLI with the provided arguments and capture its result."""
        return subprocess.run(
            [sys.executable, str(MODULE_PATH), *args],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_missing_directory_exits_with_error(self):
        with tempfile.TemporaryDirectory() as td:
            missing_dir = Path(td) / "does-not-exist"
            result = self._run_cli("--dir", str(missing_dir))
            self.assertEqual(result.returncode, 1)
            self.assertIn("not found", result.stderr)

    def test_files_mode_processes_valid_files_and_reports_success(self):
        with tempfile.TemporaryDirectory() as td:
            md_file = Path(td) / "a.md"
            md_file.write_text(
                "# Title\n\n## Table of Contents\n\n- old\n\n---\n\n## Sec One\n\ntext\n",
                encoding="utf-8",
            )
            result = self._run_cli("--files", str(md_file))
            self.assertEqual(result.returncode, 0)
            self.assertIn("[UPDATED] a.md", result.stdout)
            updated = md_file.read_text(encoding="utf-8")
            self.assertIn("- [Sec One](#Sec%20One)", updated)

    def test_files_mode_missing_file_causes_nonzero_exit_but_still_processes_valid_ones(self):
        with tempfile.TemporaryDirectory() as td:
            md_file = Path(td) / "a.md"
            md_file.write_text(
                "# Title\n\n## Table of Contents\n\n- old\n\n---\n\n## Sec One\n\ntext\n",
                encoding="utf-8",
            )
            missing_file = Path(td) / "missing.md"
            result = self._run_cli("--files", str(md_file), str(missing_file))
            self.assertEqual(result.returncode, 1)
            self.assertIn("[UPDATED] a.md", result.stdout)
            self.assertIn("skipping non-existent file", result.stderr)

    def test_dir_mode_processes_all_markdown_files(self):
        with tempfile.TemporaryDirectory() as td:
            tdp = Path(td)
            (tdp / "a.md").write_text(
                "# Title\n\n## Table of Contents\n\n- old\n\n---\n\n## Sec\n\ntext\n",
                encoding="utf-8",
            )
            (tdp / "b.md").write_text("# Title\n\nNo TOC.\n\n## Sec\n\ntext\n", encoding="utf-8")
            result = self._run_cli("--dir", str(tdp), "--style", "github")
            self.assertEqual(result.returncode, 0)
            self.assertIn("Updated 1 out of 2 files", result.stdout)

    def test_default_style_is_obsidian(self):
        result = self._run_cli("--help")
        self.assertIn("obsidian", result.stdout)


if __name__ == "__main__":
    unittest.main()