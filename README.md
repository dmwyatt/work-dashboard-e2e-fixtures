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

PRs are identified by branch name (stable) rather than PR number (changes over time).

### Your PRs (for "My Open PRs" testing)

PRs authored by dmwyatt:

| Branch | State | Purpose |
|--------|-------|---------|
| `feature/mixed-reviews` | CHANGES_REQUESTED | Review state aggregation with multiple reviewers |
| `feature/awaiting-review` | REVIEW_REQUIRED | PRs waiting for first review |
| `feature/draft-work` | Draft | Draft PR display |
| `feature/approved` | APPROVED | Approved state, LOW priority |
| `feature/with-notes` | Open | Note detection (author self-annotations) |
| `feature/extension-test` | Open | Stable target for browser extension E2E tests |

### Bot PRs (for "PRs to Review" / Review Queue testing)

PRs authored by therm-cryst, requesting review from dmwyatt:

| Branch | Your Review State | Priority |
|--------|-------------------|----------|
| `feature/bot-needs-review-v2` | None | HIGH |
| `feature/bot-with-activity` | Commented (no decision) | MEDIUM |
| `feature/bot-approved-by-you` | APPROVED | LOW |
| `feature/bot-changes-requested` | CHANGES_REQUESTED | BLOCKED |

### Aged PRs (maintained by GitHub Action)

Labeled `aged-test-fixture`, created/maintained by the workflow:

| Label | Age | Purpose |
|-------|-----|---------|
| Contains "Urgent" in title | 3+ days, no activity | Tests URGENT priority |
| Contains "Stale" in title | 7+ days, with activity | Tests STALE priority |

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
# In E2E tests (see my_dev_dashboard/e2e/conftest.py)
TEST_REPO_OWNER = "dmwyatt"
TEST_REPO_NAME = "work-dashboard-e2e-fixtures"

# Browser extension tests use the extension-test PR
# Look up PR number by branch: gh pr view feature/extension-test --json number
```

To find a PR by branch:
```bash
gh pr view feature/extension-test --json number,url
```
