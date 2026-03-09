"""YAML frontmatter parsing for SKILL.md files."""

from pathlib import Path
from typing import Optional

import strictyaml

from .errors import ParseError, ValidationError
from .models import SkillProperties


def find_skill_md(skill_dir: Path) -> Optional[Path]:
    """Find the SKILL.md file in a skill directory.

    Requires an exact SKILL.md filename.

    Args:
        skill_dir: Path to the skill directory or a direct SKILL.md file path

    Returns:
        Path to the SKILL.md file, or None if not found
    """
    if skill_dir.is_file():
        return skill_dir if skill_dir.name == "SKILL.md" else None

    if not skill_dir.is_dir():
        return None

    for path in skill_dir.iterdir():
        if path.is_file() and path.name == "SKILL.md":
            return path
    return None


def parse_frontmatter(content: str) -> tuple[dict, str]:
    """Parse YAML frontmatter from SKILL.md content.

    Args:
        content: Raw content of SKILL.md file

    Returns:
        Tuple of (metadata dict, markdown body)

    Raises:
        ParseError: If frontmatter is missing or invalid
    """
    lines = content.splitlines(keepends=True)

    if not lines or lines[0].rstrip("\r\n") != "---":
        raise ParseError("SKILL.md must start with YAML frontmatter (---)")

    closing_index = None
    for index, line in enumerate(lines[1:], start=1):
        if line.rstrip("\r\n") == "---":
            closing_index = index
            break

    if closing_index is None:
        raise ParseError("SKILL.md frontmatter not properly closed with ---")

    frontmatter_str = "".join(lines[1:closing_index])
    body = "".join(lines[closing_index + 1 :]).strip()

    try:
        parsed = strictyaml.load(frontmatter_str)
        metadata = parsed.data
    except strictyaml.YAMLError as e:
        raise ParseError(f"Invalid YAML in frontmatter: {e}")

    if not isinstance(metadata, dict):
        raise ParseError("SKILL.md frontmatter must be a YAML mapping")

    return metadata, body


def _read_optional_string_field(metadata: dict, field_name: str) -> Optional[str]:
    """Return a normalized optional string field or raise ValidationError."""
    if field_name not in metadata:
        return None

    value = metadata[field_name]
    if not isinstance(value, str) or not value.strip():
        raise ValidationError(f"Field '{field_name}' must be a non-empty string")

    return value.strip()


def _read_optional_metadata_field(metadata: dict) -> dict[str, str]:
    """Return normalized metadata or raise ValidationError."""
    if "metadata" not in metadata:
        return {}

    value = metadata["metadata"]
    if not isinstance(value, dict):
        raise ValidationError(
            "Field 'metadata' must be a mapping of string keys to string values"
        )

    normalized = {}
    for key, item in value.items():
        if not isinstance(key, str) or not isinstance(item, str):
            raise ValidationError(
                "Field 'metadata' must be a mapping of string keys to string values"
            )
        normalized[key] = item

    return normalized


def read_properties(skill_dir: Path) -> SkillProperties:
    """Read skill properties from SKILL.md frontmatter.

    This function parses the frontmatter and returns properties.
    It performs lightweight structural validation so the returned data can be
    serialized safely, but it does NOT perform full skill validation. Use
    validate() for naming conventions and other spec checks.

    Args:
        skill_dir: Path to the skill directory

    Returns:
        SkillProperties with parsed metadata

    Raises:
        ParseError: If SKILL.md is missing or has invalid YAML
        ValidationError: If required fields (name, description) are missing
    """
    skill_dir = Path(skill_dir)
    skill_md = find_skill_md(skill_dir)

    if skill_md is None:
        raise ParseError(f"SKILL.md not found in {skill_dir}")

    content = skill_md.read_text()
    metadata, _ = parse_frontmatter(content)

    if "name" not in metadata:
        raise ValidationError("Missing required field in frontmatter: name")
    if "description" not in metadata:
        raise ValidationError("Missing required field in frontmatter: description")

    name = metadata["name"]
    description = metadata["description"]

    if not isinstance(name, str) or not name.strip():
        raise ValidationError("Field 'name' must be a non-empty string")
    if not isinstance(description, str) or not description.strip():
        raise ValidationError("Field 'description' must be a non-empty string")

    return SkillProperties(
        name=name.strip(),
        description=description.strip(),
        license=_read_optional_string_field(metadata, "license"),
        compatibility=_read_optional_string_field(metadata, "compatibility"),
        allowed_tools=_read_optional_string_field(metadata, "allowed-tools"),
        metadata=_read_optional_metadata_field(metadata),
    )
