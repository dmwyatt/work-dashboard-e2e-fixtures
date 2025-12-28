# === Bot feature needs changes ===
# Created: 2025-12-28T15:04:36-06:00
# This section was added for E2E testing
# Line 4: Test fixture content
# Line 5: End of test fixture header

"""Main module for E2E test fixtures."""


def calculate_total(items: list[int]) -> int:
    """Calculate the total of a list of items."""
    return sum(items)


def format_message(name: str, count: int) -> str:
    """Format a greeting message."""
    return f"Hello {name}, you have {count} items."


def process_data(data: dict) -> dict:
    """Process input data and return results."""
    return {
        "processed": True,
        "input_keys": list(data.keys()),
        "count": len(data),
    }


if __name__ == "__main__":
    print(format_message("World", 42))
