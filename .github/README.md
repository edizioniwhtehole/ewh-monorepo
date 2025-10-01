# GitHub Configuration & CI/CD

> This folder contains GitHub-specific configuration for the EWH monorepo

## 📂 Structure

```
.github/
├── workflows/          # GitHub Actions workflows
│   ├── ci.yml         # Main CI pipeline
│   ├── pr-checks.yml  # Pull request validation
│   └── notify-deploy.yml # Deployment notifications
├── ISSUE_TEMPLATE/    # Issue templates
│   ├── bug_report.yml
│   ├── feature_request.yml
│   └── config.yml
├── pull_request_template.md # PR template
├── auto-assign.yml    # Auto-assign reviewers config
├── markdown-link-check.json # Markdown link checker config
└── README.md          # This file
```

## 🔄 Workflows

### CI Pipeline (`ci.yml`)

**Triggers:** Push to `main`/`develop`, Pull Requests

**Jobs:**
1. **Detect Changes** - Identifies which services changed
2. **Lint Documentation** - Validates markdown links and YAML
3. **Validate Structure** - Ensures all 52 submodules registered
4. **Security Scan** - Runs Trivy and TruffleHog for vulnerabilities
5. **Notify** - Sends Slack notification on failure

### PR Checks (`pr-checks.yml`)

**Triggers:** Pull request opened/updated

**Jobs:**
1. **PR Title Check** - Validates Conventional Commits format
2. **PR Size Check** - Warns if PR is too large
3. **Checklist Validator** - Checks PR checklist completion
4. **Auto-label** - Adds labels based on files changed
5. **Assign Reviewers** - Auto-assigns reviewers

### Deploy Notifications (`notify-deploy.yml`)

**Triggers:** Push to `main`/`develop`

**Jobs:**
1. **Notify Deploy** - Sends Slack notification with commit info
2. **Create Release Notes** - Creates GitHub release for production deploys

## 📝 Templates

### Issue Templates

- **Bug Report** - Structured bug reporting with severity, steps to reproduce
- **Feature Request** - Feature proposals with problem statement, solution

### Pull Request Template

Comprehensive PR template covering:
- Summary & type of change
- Testing plan
- Security considerations
- Performance impact
- Breaking changes
- Documentation updates
- Pre-merge checklist

## 🔧 Configuration

### Required Secrets

Add these in GitHub Settings → Secrets:

```bash
SLACK_WEBHOOK_URL    # Slack webhook for notifications
GITHUB_TOKEN         # Auto-provided by GitHub Actions
```

### Auto-assign Configuration

Edit `.github/auto-assign.yml` to configure:
- Reviewer list (add team member usernames)
- Number of reviewers to assign
- File pattern-based assignment (optional)

Example:
```yaml
reviewers:
  - andromeda
  - teammate1
  - teammate2

numberOfReviewers: 2
```

### Repository Settings

Recommended GitHub repository settings:

**Branches:**
- Protect `main` branch:
  - Require pull request before merging
  - Require status checks to pass: `CI - Monorepo`
  - Require conversation resolution before merging
  - Restrict who can push to matching branches
- Protect `develop` branch (same rules but less strict)

**Actions:**
- Allow all actions and reusable workflows
- Require approval for workflows from forked repos

## 🏷️ Labels

### Automatic Labels

The PR workflow automatically adds these labels:

**Service-specific:**
- `service:auth`, `service:orders`, `service:media`, etc.

**Type:**
- `tests`, `documentation`, `docker`, `ci/cd`, `database`

**Domain:**
- `domain:core`, `domain:creative`, `domain:erp`, `domain:collab`

**Size:**
- `size/S`, `size/M`, `size/L`, `size/XL`

### Manual Labels

Create these labels manually in GitHub:

```bash
# Priority
priority:critical
priority:high
priority:medium
priority:low

# Status
status:blocked
status:in-progress
status:ready-for-review
status:needs-testing

# Type
bug
enhancement
breaking-change
good-first-issue

# Special
security
performance
technical-debt
```

## 📊 Monitoring

### CI/CD Status

View workflow runs:
```
https://github.com/edizioniwhtehole/ewh-monorepo/actions
```

### Slack Notifications

Notifications sent to Slack include:
- ❌ CI pipeline failures
- 🚀 Production deployments
- 🧪 Staging deployments

Configure channel in Slack webhook URL.

## 🔐 Security

### Secret Scanning

- **TruffleHog** - Scans for committed secrets
- **Trivy** - Vulnerability scanner for dependencies

### Security Advisories

GitHub automatically:
- Scans dependencies for known vulnerabilities
- Creates Dependabot alerts
- Suggests automated security updates

Enable in: Settings → Security & analysis

## 🚀 Future Improvements

- [ ] Add service-specific CI workflows
- [ ] Implement deployment automation to Scalingo
- [ ] Add automated testing for changed services
- [ ] Set up code coverage tracking
- [ ] Add performance regression testing
- [ ] Implement automated changelog generation
- [ ] Add automated version bumping
- [ ] Set up staging environment preview deploys

## 📚 Related Documentation

- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [DEVELOPMENT.md](../DEVELOPMENT.md) - Development workflow
- [DEPLOYMENT.md](../DEPLOYMENT.md) - Deployment procedures

## 🆘 Troubleshooting

### CI Failing on Submodule Check

If CI fails with "Expected 52 submodules":
```bash
# Update submodules
git submodule update --init --recursive

# Verify count
git submodule status | wc -l

# Commit if needed
git add .gitmodules
git commit -m "fix: update submodules"
```

### PR Checks Not Running

Ensure workflows have proper permissions:
- Settings → Actions → General
- Workflow permissions: Read and write
- Allow GitHub Actions to create and approve PRs: ✓

### Slack Notifications Not Working

1. Verify webhook URL is correct in secrets
2. Test webhook:
   ```bash
   curl -X POST -H 'Content-type: application/json' \
     --data '{"text":"Test from ewh-monorepo"}' \
     YOUR_WEBHOOK_URL
   ```
3. Check Slack app permissions

---

**Maintained by:** DevOps Team
**Last updated:** 2025-10-01
