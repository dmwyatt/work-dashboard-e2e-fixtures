# Test Data Reference

Expected values for each test PR. Use these in E2E test assertions.

## PR #1: Mixed Reviews

**Purpose:** Test review state aggregation and comment indicators

**Expected GraphQL Response:**
```json
{
  "reviewDecision": "CHANGES_REQUESTED",
  "isDraft": false,
  "reviews": {
    "totalCount": 2
  },
  "reviewThreads": {
    "totalCount": 3
  },
  "comments": {
    "totalCount": 2
  }
}
```

**Expected UI:**
- Status badge: "Changes Requested" (red/orange)
- Priority: BLOCKED
- Comment indicators showing thread counts

---

## PR #2: Awaiting Review

**Purpose:** Test REVIEW_REQUIRED state

**Expected GraphQL Response:**
```json
{
  "reviewDecision": null,
  "isDraft": false,
  "reviews": {
    "totalCount": 0
  }
}
```

**Expected UI:**
- Status badge: "Review Required" or no reviews indicator
- Should appear in "My PRs" card

---

## PR #3: Draft PR

**Purpose:** Test draft PR display

**Expected GraphQL Response:**
```json
{
  "isDraft": true,
  "reviewDecision": null
}
```

**Expected UI:**
- Draft badge visible
- May be styled differently from ready PRs

---

## PR #4: Approved PR

**Purpose:** Test approved state and LOW priority

**Expected GraphQL Response:**
```json
{
  "reviewDecision": "APPROVED",
  "isDraft": false,
  "reviews": {
    "totalCount": 2
  }
}
```

**Expected UI:**
- Status badge: "Approved" (green)
- Priority: LOW

---

## PR #5: PR with Notes

**Purpose:** Test note detection (instant comments from author)

**Expected Analysis:**
```python
{
  "notes_count": 2,        # Author's self-annotations
  "feedback_threads": 1,   # Thread started by reviewer
  "viewer_code_comments": 2,
  "total_code_comments": 3
}
```

**Comment Indicators:**
- notes: 2 (green) - author's self-annotations
- code: viewer_count/total_count (purple)

---

## PR #6: Extension Test

**Purpose:** Stable PR for browser extension E2E tests

**Usage:**
```python
TEST_PR_URL = "https://github.com/{owner}/{repo}/pull/6"
```

**Extension Events to Test:**
- `page_load` on navigation
- `click` on interaction
- `scroll` with `scroll_depth`
- `tab_change` when switching PR tabs

---

# Bot-Authored PRs (for "PRs to Review" / Review Queue testing)

These PRs are authored by the bot account and request review from you.

## PR #7: Bot PR - Needs Your Review

**Purpose:** Test HIGH priority in Review Queue (new PR, no activity from you)

**Expected GraphQL Response:**
```json
{
  "author": {"login": "<bot-username>"},
  "reviewDecision": null,
  "isDraft": false
}
```

**Your State:** Not reviewed yet
**Expected Priority:** HIGH

---

## PR #8: Bot PR - With Your Comments

**Purpose:** Test MEDIUM priority (you've engaged but not submitted review)

**Expected:**
- You have PR-level comments
- You have code thread comments
- No formal review decision submitted

**Your State:** Commented only (no APPROVE/CHANGES_REQUESTED)
**Expected Priority:** MEDIUM

---

## PR #9: Bot PR - You Approved

**Purpose:** Test LOW priority (you've approved)

**Your State:** APPROVED
**Expected Priority:** LOW

---

## PR #10: Bot PR - You Requested Changes

**Purpose:** Test BLOCKED state (you've requested changes)

**Your State:** CHANGES_REQUESTED
**Expected Priority:** BLOCKED

---

# Aged PRs (maintained by GitHub Action)

## PR #11: Urgent PR (Aged)

**Purpose:** Test URGENT priority calculation

**Conditions:**
- Created 3+ days ago
- No reviews
- No comments
- Label: `aged-test-fixture`

**Expected Priority:** URGENT (highest for review queue)

---

## PR #12: Stale PR (Aged)

**Purpose:** Test STALE priority when staleness mode enabled

**Conditions:**
- Created 7+ days ago
- Has some activity (comments)
- Label: `aged-test-fixture`

**Expected:** Stale indicator when `PR_STALENESS_DAYS=7`

---

## GraphQL Query Fields Reference

Tests should verify these fields from the dashboard's GraphQL queries:

```graphql
{
  title
  url
  isDraft
  reviewDecision  # APPROVED | CHANGES_REQUESTED | null
  createdAt
  updatedAt
  repository { nameWithOwner }
  author { login }
  reviews(first: 50) {
    totalCount
    nodes {
      state  # APPROVED | CHANGES_REQUESTED | PENDING | COMMENTED
      author { login }
      createdAt
      submittedAt
    }
  }
  reviewThreads(first: 100) {
    totalCount
    nodes {
      isResolved
      comments(first: 50) {
        nodes {
          author { login }
          createdAt
          pullRequestReview {
            createdAt
            submittedAt  # == createdAt means instant comment
          }
        }
      }
    }
  }
  comments(first: 100) {
    totalCount
  }
}
```
