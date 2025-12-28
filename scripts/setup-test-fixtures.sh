#!/usr/bin/env bash
# Setup script for E2E test fixtures
# Creates PRs with various states for testing the work dashboard
#
# Prerequisites:
#   - gh CLI authenticated as primary account
#   - GH_TEST_BOT_TOKEN env var set with bot account PAT
#   - Bot account invited as collaborator to this repo

set -euo pipefail

REPO_OWNER=$(gh repo view --json owner -q '.owner.login')
REPO_NAME=$(gh repo view --json name -q '.name')
BOT_USERNAME="${BOT_USERNAME:-}"  # Set this to your bot's username

echo "Setting up test fixtures for $REPO_OWNER/$REPO_NAME"

# Check prerequisites
if [[ -z "${GH_TEST_BOT_TOKEN:-}" ]]; then
    echo "Error: GH_TEST_BOT_TOKEN environment variable not set"
    echo "Please set it to the bot account's PAT"
    exit 1
fi

# Helper function to create a branch with changes
create_branch_with_changes() {
    local branch_name="$1"
    local file_to_modify="$2"
    local change_description="$3"

    echo "Creating branch: $branch_name"

    git checkout main
    git pull origin main
    git checkout -b "$branch_name"

    # Add a comment to the file to create a change
    echo -e "\n# $change_description - $(date -Iseconds)" >> "$file_to_modify"

    git add "$file_to_modify"
    git commit -m "$change_description"
    git push -u origin "$branch_name"

    git checkout main
}

# Helper to add inline code comment via API
add_code_comment() {
    local pr_number="$1"
    local file_path="$2"
    local line="$3"
    local body="$4"
    local token="${5:-}"  # Optional: use bot token if provided

    local commit_id
    commit_id=$(gh pr view "$pr_number" --json headRefOid -q '.headRefOid')

    local gh_cmd="gh"
    if [[ -n "$token" ]]; then
        gh_cmd="GH_TOKEN=$token gh"
    fi

    eval "$gh_cmd api repos/$REPO_OWNER/$REPO_NAME/pulls/$pr_number/comments \
        -f body=\"$body\" \
        -f commit_id=\"$commit_id\" \
        -f path=\"$file_path\" \
        -F line=$line \
        -f side=RIGHT"
}

# Invite bot as collaborator (will fail silently if already invited)
echo "Inviting bot as collaborator..."
if [[ -n "$BOT_USERNAME" ]]; then
    gh api repos/$REPO_OWNER/$REPO_NAME/collaborators/$BOT_USERNAME -X PUT -f permission=push 2>/dev/null || true
fi

# ============================================================================
# PR #1: Mixed Reviews - Review state aggregation testing
# ============================================================================
echo ""
echo "=== Creating PR #1: Mixed Reviews ==="

create_branch_with_changes "feature/mixed-reviews" "src/main.py" "Add mixed reviews feature"

gh pr create \
    --base main \
    --head "feature/mixed-reviews" \
    --title "Test: Mixed Reviews" \
    --body "E2E test fixture for testing review state aggregation.

This PR should have:
- 1 APPROVED review
- 1 CHANGES_REQUESTED review
- Multiple code thread comments
- PR-level conversation comments"

PR1_NUMBER=$(gh pr view "feature/mixed-reviews" --json number -q '.number')
echo "Created PR #$PR1_NUMBER"

# Add PR-level comments
gh pr comment "$PR1_NUMBER" --body "This is a conversation comment for testing."
gh pr comment "$PR1_NUMBER" --body "Another conversation comment to verify counts."

# Add code comments (from primary account - these become "notes" since same as author in test)
add_code_comment "$PR1_NUMBER" "src/main.py" 5 "Consider adding input validation here."

# Add reviews from bot account
if [[ -n "${GH_TEST_BOT_TOKEN:-}" ]]; then
    echo "Adding bot reviews..."
    GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr review "$PR1_NUMBER" --approve --body "LGTM! Approved."

    # Add a code comment from bot, then request changes
    add_code_comment "$PR1_NUMBER" "src/main.py" 10 "This could be more efficient." "$GH_TEST_BOT_TOKEN"
    add_code_comment "$PR1_NUMBER" "src/main.py" 15 "Consider error handling here." "$GH_TEST_BOT_TOKEN"

    GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr review "$PR1_NUMBER" --request-changes --body "Some changes needed."
fi

# ============================================================================
# PR #2: Awaiting Review - REVIEW_REQUIRED state
# ============================================================================
echo ""
echo "=== Creating PR #2: Awaiting Review ==="

create_branch_with_changes "feature/awaiting-review" "src/utils.py" "Add awaiting review feature"

gh pr create \
    --base main \
    --head "feature/awaiting-review" \
    --title "Test: Awaiting Review" \
    --body "E2E test fixture for REVIEW_REQUIRED state.

This PR has review requested but no reviews submitted yet."

PR2_NUMBER=$(gh pr view "feature/awaiting-review" --json number -q '.number')
echo "Created PR #$PR2_NUMBER"

# Request review from bot (if username known)
if [[ -n "$BOT_USERNAME" ]]; then
    gh pr edit "$PR2_NUMBER" --add-reviewer "$BOT_USERNAME" || true
fi

# ============================================================================
# PR #3: Draft PR
# ============================================================================
echo ""
echo "=== Creating PR #3: Draft PR ==="

create_branch_with_changes "feature/draft-work" "src/config.py" "Work in progress draft"

gh pr create \
    --base main \
    --head "feature/draft-work" \
    --title "Test: Draft PR" \
    --body "E2E test fixture for draft PR display.

This PR is in draft state." \
    --draft

PR3_NUMBER=$(gh pr view "feature/draft-work" --json number -q '.number')
echo "Created PR #$PR3_NUMBER (draft)"

# ============================================================================
# PR #4: Approved PR - LOW priority
# ============================================================================
echo ""
echo "=== Creating PR #4: Approved PR ==="

create_branch_with_changes "feature/approved" "src/main.py" "Add approved feature"

gh pr create \
    --base main \
    --head "feature/approved" \
    --title "Test: Approved PR" \
    --body "E2E test fixture for approved state and LOW priority."

PR4_NUMBER=$(gh pr view "feature/approved" --json number -q '.number')
echo "Created PR #$PR4_NUMBER"

# Add approvals from bot
if [[ -n "${GH_TEST_BOT_TOKEN:-}" ]]; then
    GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr review "$PR4_NUMBER" --approve --body "Looks good!"
    GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr review "$PR4_NUMBER" --approve --body "Second approval."
fi

# ============================================================================
# PR #5: PR with Notes (self-annotations)
# ============================================================================
echo ""
echo "=== Creating PR #5: PR with Notes ==="

create_branch_with_changes "feature/with-notes" "src/utils.py" "Add feature with notes"

gh pr create \
    --base main \
    --head "feature/with-notes" \
    --title "Test: PR with Notes" \
    --body "E2E test fixture for note detection (instant comments from author)."

PR5_NUMBER=$(gh pr view "feature/with-notes" --json number -q '.number')
echo "Created PR #$PR5_NUMBER"

# Add self-annotations (notes) - code comments from the PR author
add_code_comment "$PR5_NUMBER" "src/utils.py" 8 "TODO: Add more validation here"
add_code_comment "$PR5_NUMBER" "src/utils.py" 15 "Note to self: refactor this later"

# Add feedback thread from bot
if [[ -n "${GH_TEST_BOT_TOKEN:-}" ]]; then
    add_code_comment "$PR5_NUMBER" "src/utils.py" 20 "This function could use some tests." "$GH_TEST_BOT_TOKEN"
fi

# ============================================================================
# PR #6: Extension Test - Stable PR for browser extension E2E
# ============================================================================
echo ""
echo "=== Creating PR #6: Extension Test ==="

create_branch_with_changes "feature/extension-test" "src/config.py" "Add extension test feature"

gh pr create \
    --base main \
    --head "feature/extension-test" \
    --title "Test: Extension Test PR" \
    --body "Stable E2E test fixture for browser extension event capture testing.

This PR is the target for extension E2E tests that verify:
- Page load events
- Click events
- Scroll events
- Tab change events"

PR6_NUMBER=$(gh pr view "feature/extension-test" --json number -q '.number')
echo "Created PR #$PR6_NUMBER"

# ============================================================================
# Create labels for aged PRs
# ============================================================================
echo ""
echo "=== Creating labels ==="
gh label create "aged-test-fixture" --description "PR maintained by CI for age-based testing" --color "FBCA04" 2>/dev/null || true

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "============================================"
echo "Setup complete!"
echo "============================================"
echo ""
echo "Created PRs:"
echo "  #$PR1_NUMBER - Mixed Reviews (CHANGES_REQUESTED)"
echo "  #$PR2_NUMBER - Awaiting Review (REVIEW_REQUIRED)"
echo "  #$PR3_NUMBER - Draft PR"
echo "  #$PR4_NUMBER - Approved PR (LOW priority)"
echo "  #$PR5_NUMBER - PR with Notes"
echo "  #$PR6_NUMBER - Extension Test (for browser extension E2E)"
echo ""
echo "Aged PRs (#7, #8) will be created by the maintain-aged-prs.sh script"
echo "and maintained by the GitHub Action."
echo ""
echo "Next steps:"
echo "1. Add GH_TEST_BOT_TOKEN as repository secret for the maintenance workflow"
echo "2. Run the maintain-aged-prs workflow manually or wait for scheduled run"
