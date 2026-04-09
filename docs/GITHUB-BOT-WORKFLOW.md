# GitHub Bot Workflow for Solo Developer + Copilot

## Overview

This guide documents the setup for a **bot account** that automatically approves pull requests created by your main developer account. This solves the GitHub branch protection requirement of needing at least one approval when you're the only human developer.

**Use case**: Solo developer + Copilot AI agent, where branch protection requires ≥1 approval before merging.

---

## Architecture

```
Your Main Account
    ↓ (creates PR)
Pull Request
    ↓ (GitHub Actions workflow triggered)
Bot Account
    ↓ (approves via GitHub API)
PR Status: Approved ✅
    ↓ (if auto-merge enabled)
Main Branch Updated
```

---

## Step 1: Create Bot Account

1. Create a new GitHub account separate from your main account
   - Use a dedicated email address (e.g., `yourname+bot@emailprovider.com`)
   - Name it descriptively: `username-bot`, `automation-bot`, or `copilot-reviewer`
   - **Important**: Use a personal account, not a team or organization account

2. Verify the bot account email

3. The bot account does not need any repositories or profile setup

---

## Step 2: Add Bot as Repository Collaborator

### Via GitHub Web UI (Recommended)

1. Sign in to your **main account**
2. Go to your repository on GitHub
3. Click **Settings** → **Collaborators** (or **Access** → **Collaborators**)
4. Click **Add people**
5. Search for the bot account username
6. Select role: **Write** (allows approving PRs and merging)
7. Click **Add**

The bot account will receive an email invitation.

### Via Bot Account

1. Sign in to the **bot account**
2. Check the email for a GitHub repository invitation
3. Click the invitation link or visit https://github.com/notifications/invitations
4. Click **Accept** to join the repository

**Verification**: After the bot accepts, the bot should appear as a collaborator in your repo settings with "Write" role.

---

## Step 3: Create Personal Access Token for Bot

**Sign in as the bot account**, then:

1. Go to **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. Configure the token:
   - **Token name**: `PR Approver Token` (or descriptive name)
   - **Expiration**: `90 days` (or as per your security policy)
   - **Scopes**: Select only **`repo`** (full control of private repositories)
4. Click **Generate token**
5. **Copy the token immediately** — GitHub will not show it again

**Security**: Store this token securely. Never commit it to version control.

---

## Step 4: Store Token as GitHub Actions Secret

**Sign in to your main account**, then:

1. Go to your repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Configure:
   - **Name**: Choose a descriptive name (e.g., `BOT_APPROVAL_TOKEN`, `BOT_PAT`)
   - **Value**: Paste the token from Step 3
5. Click **Add secret**

**Note**: The secret name will be referenced in your GitHub Actions workflow. Do not share this secret name publicly.

---

## Step 5: Create GitHub Actions Workflow

Create a new file in your repository:

**Path**: `.github/workflows/auto-approve-pr.yml`

**Content**:

```yaml
name: Auto-Approve PR

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  approve:
    runs-on: ubuntu-latest
    # Only auto-approve PRs created by YOUR main account
    # Replace 'your-main-username' with your actual GitHub username
    if: github.actor == 'your-main-username'
    steps:
      - name: Approve Pull Request
        uses: actions/github-script@v6
        with:
          # Use the secret name you created in Step 4
          github-token: ${{ secrets.BOT_APPROVAL_TOKEN }}
          script: |
            github.rest.pulls.createReview({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number,
              event: 'APPROVE',
              body: 'Auto-approved by bot after author review. ✅'
            })
```

### Workflow Explanation

- **Trigger**: Runs when a PR is opened or updated (`opened`, `synchronize`)
- **Condition**: Only runs if the PR creator (`github.actor`) is your main account
- **Action**: Uses the bot's authentication token to approve the PR via GitHub API
- **Comment**: Leaves an automated message in the PR

### Customization

Replace these placeholders:
- `your-main-username` → Your GitHub username
- `BOT_APPROVAL_TOKEN` → The secret name you chose in Step 4

---

## Step 6: Optional - Enable Auto-Merge

To automatically merge PRs after bot approval (requires all status checks to pass):

### In GitHub Repository Settings

1. Go to **Settings** → **Pull Requests**
2. Enable **Allow auto-merge**
3. Optionally select default merge method (Squash, Merge, or Rebase)

### In Workflow (Optional)

Add this step to `.github/workflows/auto-approve-pr.yml` to enable auto-merge programmatically:

```yaml
      - name: Enable Auto-Merge
        uses: actions/github-script@v6
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            github.rest.pulls.enableAutomerge({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number,
              merge_method: 'squash'
            })
```

---

## Step 7: Configure Branch Protection Rules

To enforce the approval requirement:

1. Go to **Settings** → **Branches**
2. Click **Add rule** (or edit existing protection for main/master branch)
3. Branch name pattern: `main` (or your default branch)
4. Enable these protections:
   - ✅ **Require a pull request before merging**
   - ✅ **Require approvals**: Set to `1` required approval
   - ✅ **Require status checks to pass** (if you have tests/linting)
   - ✅ **Require conversation resolution**
   - ✅ **Allow auto-merge** (optional, for automatic merging)

With the bot as a collaborator and the auto-approval workflow, the approval requirement is now satisfied automatically.

---

## Your New Workflow

### Quick Reference

```bash
# 1. Create feature branch
git checkout -b feature/my-feature
git commit -m "Add feature X"
git push -u origin feature/my-feature

# 2. Create PR (via GitHub UI or CLI)
# GitHub UI: Click "Compare & pull request"
# OR via CLI:
gh pr create --title "Add feature X" --body "Description of changes"

# 3. Automatic steps:
#    - GitHub Actions workflow triggers
#    - Bot account approves the PR
#    - (Optional) PR auto-merges if status checks pass

# 4. Result: Changes merged to main branch
```

### Manual Step-by-Step (if not using auto-merge)

1. Push feature branch and create PR
2. Review PR changes in GitHub UI (check diffs, comments, test results)
3. Workflow auto-approves PR
4. Click **Merge pull request** button
5. Main branch is updated

---

## Security Considerations

### Best Practices

- ✅ **Approval condition**: Workflow only approves PRs created by your main account (prevents unauthorized approvals)
- ✅ **Token storage**: Store bot's PAT in GitHub Actions secrets (never in code or environment variables)
- ✅ **Token scope**: Bot token uses minimal scope (`repo` only)
- ✅ **Role restriction**: Bot has "Write" access (can approve/merge, not admin)

### Token Maintenance

- **Expiration**: Token expires after the configured period (e.g., 90 days)
- **Rotation**: Regenerate and update the GitHub Actions secret when token expires
- **Exposure**: If token is compromised, regenerate immediately and update the secret

### What the Bot Cannot Do

- Approve PRs created by other users (blocked by `if: github.actor == 'your-main-username'` condition)
- Make code changes or push to branches
- Modify repository settings
- Delete repository

---

## Testing the Setup

1. Create a test feature branch with a small change
2. Push and create a PR
3. Observe the GitHub Actions workflow:
   - Go to PR → **Checks** tab
   - Look for the "Auto-Approve PR" workflow
   - It should show status: ✅ Passed
4. Verify bot account appears as "Approved" in the PR review section
5. Confirm PR can now be merged (if branch protection allows)

---

## Troubleshooting

### Workflow Doesn't Run

- Check that the PR creator (`github.actor`) matches `your-main-username` in the workflow condition
- Verify the workflow file is in `.github/workflows/` directory
- Check **Actions** tab in your repo for workflow run history and logs

### "403 Forbidden" or "404 Not Found"

- Verify bot account is added as a collaborator with "Write" role
- Confirm the secret exists in repository **Settings → Secrets and variables**
- Check that secret name in workflow matches the actual secret name you created

### Bot Doesn't Approve

- Review workflow logs in **Actions** tab to see error messages
- Verify bot account PAT token hasn't expired
- Confirm bot account email is verified on GitHub

### How to View Workflow Logs

1. Go to your repository
2. Click **Actions** tab
3. Click the workflow run name (e.g., "Auto-Approve PR")
4. Click the job name (e.g., "approve")
5. Expand steps to see detailed logs

---

## Alternative Approaches

If the bot account approach doesn't work for your use case:

### Option A: Disable Approval Requirement
- Remove the approval requirement from branch protection
- Keep other protections: status checks, conversation resolution, linear history
- Trade-off: No gatekeeping for PRs, but faster workflow for solo development

### Option B: Use GitHub Rulesets (Modern Alternative)
- GitHub Rulesets provide more granular control than branch protection rules
- Allows excluding specific users/apps from certain requirements
- Better for complex scenarios with multiple permission levels

---

## References

- [GitHub REST API - Pull Request Reviews](https://docs.github.com/en/rest/pulls/reviews)
- [GitHub Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
- [GitHub Actions - github-script](https://github.com/actions/github-script)
- [Personal Access Tokens - GitHub Docs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
