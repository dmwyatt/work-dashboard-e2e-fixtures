#!/usr/bin/env bash
# Maintenance script for aged test PRs
# Called by GitHub Actions to ensure PRs with specific ages exist
#
# Manages two types of aged PRs:
# - "urgent": 3+ days old with no activity
# - "stale": 7+ days old with some activity

set -euo pipefail

# Hardcoded for safety - this script should only run on the test fixtures repo
REPO_OWNER="dmwyatt"
REPO_NAME="work-dashboard-e2e-fixtures"

# Safety check: verify we're in the correct repo
CURRENT_REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
EXPECTED_REPO="$REPO_OWNER/$REPO_NAME"

if [[ "$CURRENT_REPO" != "$EXPECTED_REPO" ]]; then
    echo "ERROR: This script must be run from the $EXPECTED_REPO repository."
    echo "Current repo: ${CURRENT_REPO:-'(not a git repo or no remote)'}"
    echo "Aborting for safety."
    exit 1
fi

URGENT_AGE_DAYS=3
STALE_AGE_DAYS=7

echo "Maintaining aged PRs for $REPO_OWNER/$REPO_NAME"

# Get current date in seconds since epoch
NOW=$(date +%s)

# Helper: Calculate age in days from ISO date
days_since() {
    local iso_date="$1"
    local created_seconds
    created_seconds=$(date -d "$iso_date" +%s)
    local diff=$((NOW - created_seconds))
    echo $((diff / 86400))
}

# Helper: Create a new aged PR
create_aged_pr() {
    local pr_type="$1"  # "urgent" or "stale"
    local base_branch="feature/${pr_type}-$(date +%Y%m%d%H%M%S)"
    local file_to_modify
    local title
    local body

    if [[ "$pr_type" == "urgent" ]]; then
        file_to_modify="src/main.py"
        title="Test: Urgent PR (no reviews, aging)"
        body="E2E test fixture for URGENT priority testing.

This PR is intentionally left without reviews to test the urgent priority indicator.
It should be 3+ days old with no activity.

**Do not review or comment on this PR** - it's automatically maintained for testing.

Label: aged-test-fixture"
    else
        file_to_modify="src/utils.py"
        title="Test: Stale PR (aged 7+ days)"
        body="E2E test fixture for STALE priority testing.

This PR tests the staleness indicator for PRs older than 7 days.

Label: aged-test-fixture"
    fi

    echo "Creating new $pr_type PR with branch $base_branch"

    git checkout main
    git pull origin main
    git checkout -b "$base_branch"

    echo -e "\n# Aged PR fixture - $pr_type - $(date -Iseconds)" >> "$file_to_modify"

    git add "$file_to_modify"
    git commit -m "Aged PR fixture: $pr_type type"
    git push -u origin "$base_branch"

    gh pr create \
        --base main \
        --head "$base_branch" \
        --title "$title" \
        --body "$body" \
        --label "aged-test-fixture"

    local pr_number
    pr_number=$(gh pr view "$base_branch" --json number -q '.number')
    echo "Created PR #$pr_number for $pr_type"

    # For stale PRs, add some activity (a comment)
    if [[ "$pr_type" == "stale" ]]; then
        gh pr comment "$pr_number" --body "Initial activity for stale PR testing."
    fi

    git checkout main
}

# Helper: Close a PR
close_pr() {
    local pr_number="$1"
    echo "Closing PR #$pr_number"
    gh pr close "$pr_number" --delete-branch || true
}

# Find existing aged PRs by label
echo ""
echo "Checking existing aged PRs..."

URGENT_PRS=$(gh pr list --label "aged-test-fixture" --json number,title,createdAt -q '.[] | select(.title | contains("Urgent")) | "\(.number)|\(.createdAt)"')
STALE_PRS=$(gh pr list --label "aged-test-fixture" --json number,title,createdAt -q '.[] | select(.title | contains("Stale")) | "\(.number)|\(.createdAt)"')

# Process urgent PRs
echo ""
echo "=== Processing Urgent PRs ==="
VALID_URGENT_PR=""
while IFS='|' read -r pr_number created_at; do
    if [[ -z "$pr_number" ]]; then continue; fi

    age_days=$(days_since "$created_at")
    echo "PR #$pr_number is $age_days days old"

    if [[ $age_days -ge $URGENT_AGE_DAYS ]]; then
        if [[ -z "$VALID_URGENT_PR" ]]; then
            echo "  -> Valid urgent PR (keeping)"
            VALID_URGENT_PR="$pr_number"
        else
            echo "  -> Duplicate valid urgent PR (closing)"
            close_pr "$pr_number"
        fi
    else
        echo "  -> Not yet old enough, keeping to age"
        if [[ -z "$VALID_URGENT_PR" ]]; then
            VALID_URGENT_PR="$pr_number"
        fi
    fi
done <<< "$URGENT_PRS"

if [[ -z "$VALID_URGENT_PR" ]]; then
    echo "No urgent PR found, creating new one..."
    create_aged_pr "urgent"
else
    echo "Have urgent PR #$VALID_URGENT_PR"
fi

# Process stale PRs
echo ""
echo "=== Processing Stale PRs ==="
VALID_STALE_PR=""
while IFS='|' read -r pr_number created_at; do
    if [[ -z "$pr_number" ]]; then continue; fi

    age_days=$(days_since "$created_at")
    echo "PR #$pr_number is $age_days days old"

    if [[ $age_days -ge $STALE_AGE_DAYS ]]; then
        if [[ -z "$VALID_STALE_PR" ]]; then
            echo "  -> Valid stale PR (keeping)"
            VALID_STALE_PR="$pr_number"
        else
            echo "  -> Duplicate valid stale PR (closing)"
            close_pr "$pr_number"
        fi
    else
        echo "  -> Not yet old enough, keeping to age"
        if [[ -z "$VALID_STALE_PR" ]]; then
            VALID_STALE_PR="$pr_number"
        fi
    fi
done <<< "$STALE_PRS"

if [[ -z "$VALID_STALE_PR" ]]; then
    echo "No stale PR found, creating new one..."
    create_aged_pr "stale"
else
    echo "Have stale PR #$VALID_STALE_PR"
fi

echo ""
echo "=== Maintenance complete ==="
