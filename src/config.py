# === Work in progress draft ===
# Created: 2025-12-28T14:57:41-06:00
# This section was added for E2E testing
# Line 4: Test fixture content
# Line 5: End of test fixture header

"""Configuration settings for E2E test fixtures."""

# Default settings
DEFAULT_TIMEOUT = 30
MAX_RETRIES = 3
DEBUG_MODE = False

# Feature flags
ENABLE_CACHING = True
ENABLE_LOGGING = True
ENABLE_METRICS = False


def get_config() -> dict:
    """Return current configuration as dictionary."""
    return {
        "timeout": DEFAULT_TIMEOUT,
        "max_retries": MAX_RETRIES,
        "debug": DEBUG_MODE,
        "features": {
            "caching": ENABLE_CACHING,
            "logging": ENABLE_LOGGING,
            "metrics": ENABLE_METRICS,
        },
    }


def is_feature_enabled(feature: str) -> bool:
    """Check if a feature flag is enabled."""
    config = get_config()
    return config.get("features", {}).get(feature, False)
