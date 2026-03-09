"""Tests for CLI commands."""

from click.testing import CliRunner

from skills_ref.cli import main


def test_validate_accepts_skill_md_path(tmp_path):
    skill_dir = tmp_path / "my-skill"
    skill_dir.mkdir()
    skill_md = skill_dir / "SKILL.md"
    skill_md.write_text("""---
name: my-skill
description: A test skill
---
Body
""")

    runner = CliRunner()
    result = runner.invoke(main, ["validate", str(skill_md)])

    assert result.exit_code == 0
    assert "Valid skill:" in result.output


def test_read_properties_rejects_invalid_optional_field(tmp_path):
    skill_dir = tmp_path / "my-skill"
    skill_dir.mkdir()
    skill_md = skill_dir / "SKILL.md"
    skill_md.write_text("""---
name: my-skill
description: A test skill
metadata:
  author:
    nested: nope
---
Body
""")

    runner = CliRunner()
    result = runner.invoke(main, ["read-properties", str(skill_md)])

    assert result.exit_code == 1
    assert "metadata" in result.output


def test_to_prompt_accepts_skill_md_path(tmp_path):
    skill_dir = tmp_path / "my-skill"
    skill_dir.mkdir()
    skill_md = skill_dir / "SKILL.md"
    skill_md.write_text("""---
name: my-skill
description: A test skill
---
Body
""")

    runner = CliRunner()
    result = runner.invoke(main, ["to-prompt", str(skill_md)])

    assert result.exit_code == 0
    assert "<available_skills>" in result.output
    assert "my-skill" in result.output
