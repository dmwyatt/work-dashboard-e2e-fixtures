"""Tests for main module."""

import pytest
from src.main import calculate_total, format_message, process_data


def test_calculate_total_empty():
    """Test calculate_total with empty list."""
    assert calculate_total([]) == 0


def test_calculate_total_single():
    """Test calculate_total with single item."""
    assert calculate_total([5]) == 5


def test_calculate_total_multiple():
    """Test calculate_total with multiple items."""
    assert calculate_total([1, 2, 3, 4, 5]) == 15


def test_format_message():
    """Test format_message output."""
    result = format_message("Alice", 10)
    assert result == "Hello Alice, you have 10 items."


def test_process_data():
    """Test process_data returns expected structure."""
    data = {"a": 1, "b": 2}
    result = process_data(data)
    assert result["processed"] is True
    assert result["count"] == 2
    assert set(result["input_keys"]) == {"a", "b"}
