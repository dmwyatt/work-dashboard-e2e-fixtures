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

### Your PRs (for "My Open PRs" testing)

PRs authored by the primary account:

| PR # | Name | State | Purpose |
|------|------|-------|---------|
| #1 | Mixed Reviews | CHANGES_REQUESTED | Tests review state aggregation with multiple reviewers |
| #2 | Awaiting Review | REVIEW_REQUIRED | Tests PRs waiting for first review |
| #3 | Draft PR | Draft | Tests draft PR display |
| #4 | Approved PR | APPROVED | Tests approved state and LOW priority |
| #5 | PR with Notes | Open | Tests note detection (author self-annotations) |
| #6 | Extension Test | Open | Stable target for browser extension E2E tests |

### Bot PRs (for "PRs to Review" / Review Queue testing)

PRs authored by the bot account, requesting review from you:

| PR # | Name | Your Review State | Priority |
|------|------|-------------------|----------|
| #7 | Bot PR - Needs Review | None | HIGH |
| #8 | Bot PR - With Comments | Commented (no decision) | MEDIUM |
| #9 | Bot PR - You Approved | APPROVED | LOW |
| #10 | Bot PR - Changes Requested | CHANGES_REQUESTED | BLOCKED |

### Aged PRs (maintained by GitHub Action)

| PR # | Age | Purpose |
|------|-----|---------|
| #11* | 3+ days | Tests URGENT priority (no activity) |
| #12* | 7+ days | Tests STALE priority |

*Aged PRs are created and maintained by the `maintain-aged-prs` workflow.

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
