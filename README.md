# Work Dashboard E2E Test Fixtures

This repository provides controlled test data for end-to-end testing of the [Work Dashboard](https://github.com/dmwyatt/my_dev_dashboard) project.

## Purpose

The Work Dashboard aggregates GitHub PR data. This test repo contains PRs in known states for E2E tests to verify:

- PR display by review status
- Review state aggregation
- Comment/thread analysis
- Priority calculation (urgent, stale, etc.)
- Browser extension event capture

## Test PRs

| PR # | Name | State | Purpose |
|------|------|-------|---------|
| #1 | Mixed Reviews | CHANGES_REQUESTED | Tests review state aggregation with multiple reviewers |
| #2 | Awaiting Review | REVIEW_REQUIRED | Tests PRs waiting for first review |
| #3 | Draft PR | Draft | Tests draft PR display |
| #4 | Approved PR | APPROVED | Tests approved state and LOW priority |
| #5 | PR with Notes | Open | Tests note detection (author self-annotations) |
| #6 | Extension Test | Open | Stable target for browser extension E2E tests |
| #7* | Urgent PR | Open, 3+ days | Tests URGENT priority (no activity, aged) |
| #8* | Stale PR | Open, 7+ days | Tests STALE priority (aged with activity) |

*Aged PRs (#7, #8) are maintained by a GitHub Action that runs daily.

## Setup

The test fixtures are created by `scripts/setup-test-fixtures.sh`. This requires:

1. `gh` CLI authenticated as the primary account
2. `GH_TEST_BOT_TOKEN` env var with bot account PAT
3. Bot account invited as collaborator

See `TEST_DATA.md` for detailed expected values for each PR.

## Maintenance

Aged PRs are maintained automatically by the `maintain-aged-prs` workflow which:
- Runs daily at 6am UTC
- Creates new aged PRs when needed
- Closes duplicates to keep exactly one of each type

## Usage in Tests

```python
# In E2E tests
TEST_REPO_OWNER = "dmwyatt"
TEST_REPO_NAME = "work-dashboard-e2e-fixtures"

# Browser extension tests use PR #6
TEST_PR_NUMBER = 6
```
