# === Add awaiting review feature ===
# Created: 2025-12-28T14:57:34-06:00
# This section was added for E2E testing
# Line 4: Test fixture content
# Line 5: End of test fixture header

"""Utility functions for E2E test fixtures."""

from datetime import datetime


def get_timestamp() -> str:
    """Return current timestamp as ISO string."""
    return datetime.now().isoformat()


def validate_input(value: str) -> bool:
    """Validate that input is non-empty string."""
    return bool(value and value.strip())


def merge_dicts(dict1: dict, dict2: dict) -> dict:
    """Merge two dictionaries."""
    return {**dict1, **dict2}


def truncate_string(text: str, max_length: int = 100) -> str:
    """Truncate string to max length with ellipsis."""
    if len(text) <= max_length:
        return text
    return text[: max_length - 3] + "..."
