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
gh label create "review-queue-test" --description "Bot-authored PR for Review Queue testing" --color "1D76DB" 2>/dev/null || true

# ============================================================================
# BOT-AUTHORED PRs (for "PRs to Review" / Review Queue testing)
# These PRs are created BY the bot, requesting review FROM the primary user
# ============================================================================

# Get primary user's username for requesting reviews
PRIMARY_USERNAME=$(gh api user -q '.login')

# Helper function to create a branch with changes using bot credentials
create_bot_branch_with_changes() {
    local branch_name="$1"
    local file_to_modify="$2"
    local change_description="$3"

    echo "Creating bot branch: $branch_name"

    git checkout main
    git pull origin main
    git checkout -b "$branch_name"

    # Add a comment to the file to create a change
    echo -e "\n# $change_description (bot) - $(date -Iseconds)" >> "$file_to_modify"

    git add "$file_to_modify"
    git commit -m "$change_description"

    # Push using bot token
    git push -u origin "$branch_name"

    git checkout main
}

echo ""
echo "=== Creating Bot-Authored PRs (for Review Queue testing) ==="

# ============================================================================
# PR #7: Bot PR - Needs Your Review (HIGH priority - new, no activity)
# ============================================================================
echo ""
echo "=== Creating PR #7: Bot PR - Needs Review ==="

create_bot_branch_with_changes "feature/bot-needs-review" "src/main.py" "Bot feature needing review"

GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr create \
    --base main \
    --head "feature/bot-needs-review" \
    --title "Test: Bot PR - Needs Your Review" \
    --body "E2E test fixture for Review Queue testing.

This PR is authored by the bot and requests review from the primary user.
It should appear in the 'PRs to Review' section of the dashboard." \
    --label "review-queue-test"

PR7_NUMBER=$(GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr view "feature/bot-needs-review" --json number -q '.number')
echo "Created PR #$PR7_NUMBER (bot-authored)"

# Request review from primary user
GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr edit "$PR7_NUMBER" --add-reviewer "$PRIMARY_USERNAME" || true

# ============================================================================
# PR #8: Bot PR - With Your Comments (MEDIUM priority - has activity)
# ============================================================================
echo ""
echo "=== Creating PR #8: Bot PR - With Activity ==="

create_bot_branch_with_changes "feature/bot-with-activity" "src/utils.py" "Bot feature with activity"

GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr create \
    --base main \
    --head "feature/bot-with-activity" \
    --title "Test: Bot PR - With Your Comments" \
    --body "E2E test fixture for Review Queue with activity.

This PR has comments from the primary user (you) but no review decision yet." \
    --label "review-queue-test"

PR8_NUMBER=$(GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr view "feature/bot-with-activity" --json number -q '.number')
echo "Created PR #$PR8_NUMBER (bot-authored)"

# Request review from primary user
GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr edit "$PR8_NUMBER" --add-reviewer "$PRIMARY_USERNAME" || true

# Add comments from primary user (simulating engagement)
gh pr comment "$PR8_NUMBER" --body "I've started looking at this, will review soon."
add_code_comment "$PR8_NUMBER" "src/utils.py" 5 "Question: why this approach instead of X?"

# ============================================================================
# PR #9: Bot PR - You Approved (LOW priority)
# ============================================================================
echo ""
echo "=== Creating PR #9: Bot PR - You Approved ==="

create_bot_branch_with_changes "feature/bot-approved-by-you" "src/config.py" "Bot feature you approved"

GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr create \
    --base main \
    --head "feature/bot-approved-by-you" \
    --title "Test: Bot PR - You Approved" \
    --body "E2E test fixture for Review Queue with your approval.

This PR shows as LOW priority since you've already approved it." \
    --label "review-queue-test"

PR9_NUMBER=$(GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr view "feature/bot-approved-by-you" --json number -q '.number')
echo "Created PR #$PR9_NUMBER (bot-authored)"

# Request review and approve as primary user
GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr edit "$PR9_NUMBER" --add-reviewer "$PRIMARY_USERNAME" || true
gh pr review "$PR9_NUMBER" --approve --body "LGTM!"

# ============================================================================
# PR #10: Bot PR - You Requested Changes (BLOCKED)
# ============================================================================
echo ""
echo "=== Creating PR #10: Bot PR - You Requested Changes ==="

create_bot_branch_with_changes "feature/bot-changes-requested" "src/main.py" "Bot feature needs changes"

GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr create \
    --base main \
    --head "feature/bot-changes-requested" \
    --title "Test: Bot PR - You Requested Changes" \
    --body "E2E test fixture for Review Queue with changes requested.

This PR shows as BLOCKED since you've requested changes." \
    --label "review-queue-test"

PR10_NUMBER=$(GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr view "feature/bot-changes-requested" --json number -q '.number')
echo "Created PR #$PR10_NUMBER (bot-authored)"

# Request review and request changes as primary user
GH_TOKEN="$GH_TEST_BOT_TOKEN" gh pr edit "$PR10_NUMBER" --add-reviewer "$PRIMARY_USERNAME" || true
gh pr review "$PR10_NUMBER" --request-changes --body "Please fix the issues mentioned in my comments."
add_code_comment "$PR10_NUMBER" "src/main.py" 8 "This needs error handling."

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "============================================"
echo "Setup complete!"
echo "============================================"
echo ""
echo "Your PRs (for 'My Open PRs' testing):"
echo "  #$PR1_NUMBER - Mixed Reviews (CHANGES_REQUESTED)"
echo "  #$PR2_NUMBER - Awaiting Review (REVIEW_REQUIRED)"
echo "  #$PR3_NUMBER - Draft PR"
echo "  #$PR4_NUMBER - Approved PR (LOW priority)"
echo "  #$PR5_NUMBER - PR with Notes"
echo "  #$PR6_NUMBER - Extension Test (for browser extension E2E)"
echo ""
echo "Bot PRs (for 'PRs to Review' / Review Queue testing):"
echo "  #$PR7_NUMBER - Needs Your Review (HIGH priority)"
echo "  #$PR8_NUMBER - With Your Comments (MEDIUM priority)"
echo "  #$PR9_NUMBER - You Approved (LOW priority)"
echo "  #$PR10_NUMBER - You Requested Changes (BLOCKED)"
echo ""
echo "Aged PRs will be created by the maintain-aged-prs.sh script"
echo "and maintained by the GitHub Action."
echo ""
echo "Next steps:"
echo "1. Add GH_TEST_BOT_TOKEN as repository secret for the maintenance workflow"
echo "2. Run the maintain-aged-prs workflow manually or wait for scheduled run"
