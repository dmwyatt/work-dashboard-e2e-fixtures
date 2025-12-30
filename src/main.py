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

# Aged PR fixture - urgent - 2025-12-30T06:11:17+00:00
