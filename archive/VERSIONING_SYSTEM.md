# 📦 Versioning System - Semantic Versioning & Changelog

**Version**: 1.0.0
**Last Updated**: 2025-10-11
**Status**: ✅ Complete Specification

---

## 🎯 Overview

Sistema di versioning basato su **Semantic Versioning 2.0.0** con codename, changelog automatico, e API versioning.

---

## 📊 Semantic Versioning (SemVer)

### Format

```
v{MAJOR}.{MINOR}.{PATCH}[-{PRERELEASE}][+{BUILD}]

Examples:
v1.0.0           - Release stabile
v1.1.0           - Nuove feature, backward compatible
v1.1.1           - Bug fix
v2.0.0           - Breaking changes
v2.0.0-beta.1    - Pre-release
v2.0.0+20251011  - Build metadata
```

### Numbering Rules

| Type | When to Increment | Example |
|------|-------------------|---------|
| **MAJOR** | Breaking changes (API incompatibile) | v1.5.3 → v2.0.0 |
| **MINOR** | Nuove feature, backward compatible | v1.5.3 → v1.6.0 |
| **PATCH** | Bug fixes, no new features | v1.5.3 → v1.5.4 |

---

## 🏷️ Codename System

### Major Versions have Codenames

```
v1.x.x - "Aurora"    (First light)
v2.x.x - "Nebula"    (Expansion)
v3.x.x - "Quasar"    (Power)
v4.x.x - "Cosmos"    (Universe)
v5.x.x - "Eclipse"   (Transformation)
```

**Marketing**: Più facile ricordare "Aurora" che "v1.2.5"

---

## 📅 Version Numbering Strategy

### Current Version

```typescript
// package.json (root)
{
  "name": "@ewh/platform",
  "version": "1.0.0",
  "codename": "Aurora"
}
```

### Version in Code

```typescript
// packages/core/version/src/index.ts

export const VERSION = {
  major: 1,
  minor: 0,
  patch: 0,
  codename: 'Aurora',
  full: '1.0.0',
  display: 'v1.0.0 "Aurora"',
  build: '20251011', // YYYYMMDD
};

export function getVersion(): string {
  return VERSION.display;
}
```

### Version API

```typescript
// GET /api/version

app.get('/api/version', (req, res) => {
  res.json({
    version: VERSION.full,
    codename: VERSION.codename,
    build: VERSION.build,
    environment: process.env.NODE_ENV
  });
});
```

---

## 📝 Changelog

### Format (Keep a Changelog)

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature X in development

## [1.1.0] - 2025-11-15

### Added
- AI Assistant widget in dashboard
- Real-time collaboration on documents
- Webhooks retry with exponential backoff

### Changed
- Improved performance of CMS queries (50% faster)
- Updated UI theme system with tenant overrides

### Fixed
- Fixed memory leak in WebSocket connections
- Fixed timezone display bug in calendar

### Security
- Added rate limiting to API endpoints
- Implemented MFA for admin accounts

## [1.0.1] - 2025-10-20

### Fixed
- Fixed login redirect issue
- Fixed file upload for large files (>100MB)

## [1.0.0] - 2025-10-11 - "Aurora"

### Added
- Initial release
- CMS with posts, pages, media
- Multi-tenant architecture
- User authentication and authorization
- Dashboard with widgets
- API gateway
- Documentation system
```

---

## 🔧 Changelog Generation (Automated)

### From Git Commits

```bash
# scripts/generate-changelog.sh

#!/bin/bash

# Get commits since last tag
LAST_TAG=$(git describe --tags --abbrev=0)
COMMITS=$(git log $LAST_TAG..HEAD --pretty=format:"%s" --no-merges)

# Parse commits by type (Conventional Commits)
echo "## [Unreleased]"
echo ""

# Added
echo "### Added"
echo "$COMMITS" | grep "^feat:" | sed 's/^feat: /- /'
echo ""

# Changed
echo "### Changed"
echo "$COMMITS" | grep "^change:" | sed 's/^change: /- /'
echo ""

# Fixed
echo "### Fixed"
echo "$COMMITS" | grep "^fix:" | sed 's/^fix: /- /'
echo ""

# Security
echo "### Security"
echo "$COMMITS" | grep "^security:" | sed 's/^security: /- /'
```

### Conventional Commits

```
feat: add AI assistant widget
fix: resolve memory leak in WebSocket
docs: update API documentation
style: format code with prettier
refactor: simplify authentication logic
test: add unit tests for webhook service
chore: update dependencies
security: add rate limiting to API
```

---

## 🔢 Versioning Database

```sql
-- db_blogmaster_platform.versions

CREATE TABLE versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Version
  major INT NOT NULL,
  minor INT NOT NULL,
  patch INT NOT NULL,
  prerelease VARCHAR(50),
  codename VARCHAR(50),

  -- Metadata
  released_at TIMESTAMP NOT NULL DEFAULT NOW(),
  changelog TEXT,
  breaking_changes TEXT[],

  -- Git
  git_commit_sha VARCHAR(40),
  git_branch VARCHAR(100),

  INDEX idx_version (major, minor, patch)
);

-- Insert new version
INSERT INTO versions (major, minor, patch, codename, changelog, git_commit_sha) VALUES
  (1, 0, 0, 'Aurora', '# Changelog\n\n## v1.0.0 "Aurora"\n\n### Added\n- Initial release', 'abc123def456');
```

---

## 🔀 API Versioning

### URL-Based Versioning

```
/api/v1/posts     - Version 1 API
/api/v2/posts     - Version 2 API (breaking changes)
```

### Implementation

```typescript
// packages/svc-api-gateway/src/versioning.ts

export function versionRouter() {
  const router = express.Router();

  // v1 routes
  router.use('/v1', v1Router);

  // v2 routes
  router.use('/v2', v2Router);

  // Default to latest stable
  router.use('/', v1Router); // or v2Router quando stable

  return router;
}

// v1Router (backward compatible)
const v1Router = express.Router();

v1Router.get('/posts', async (req, res) => {
  const posts = await db.query('SELECT * FROM posts');
  res.json(posts.rows);
});

// v2Router (breaking changes)
const v2Router = express.Router();

v2Router.get('/posts', async (req, res) => {
  const posts = await db.query(`
    SELECT
      id,
      title,
      content,
      author_id,
      created_at,
      -- NEW FIELDS in v2
      tags,
      featured_image
    FROM posts
  `);
  res.json(posts.rows);
});
```

---

## 📊 Version Migration Strategy

### Database Migrations

```typescript
// migrations/002_add_tags_to_posts.sql
-- Version: 1.1.0
-- Breaking: false

ALTER TABLE schema_cms.posts ADD COLUMN tags TEXT[];
ALTER TABLE schema_cms.posts ADD COLUMN featured_image TEXT;

-- Backfill data
UPDATE schema_cms.posts SET tags = '{}' WHERE tags IS NULL;
```

### Breaking Changes Migration

```typescript
// migrations/010_rename_author_to_creator.sql
-- Version: 2.0.0
-- Breaking: true

ALTER TABLE schema_cms.posts RENAME COLUMN author_id TO creator_id;

-- Update API response mapping in v1 for backward compatibility
-- v1 API will map creator_id back to author_id in response
```

---

## 🚀 Release Process

### 1. Update Version

```bash
# Bump version
npm version major   # 1.5.3 → 2.0.0
npm version minor   # 1.5.3 → 1.6.0
npm version patch   # 1.5.3 → 1.5.4

# This updates package.json and creates a git tag
```

### 2. Generate Changelog

```bash
./scripts/generate-changelog.sh > CHANGELOG_NEW.md
# Review and merge into CHANGELOG.md
```

### 3. Update Codename (if major)

```typescript
// packages/core/version/src/index.ts
export const VERSION = {
  major: 2,
  minor: 0,
  patch: 0,
  codename: 'Nebula', // NEW
  // ...
};
```

### 4. Create Git Tag

```bash
git tag -a v2.0.0 -m "Release v2.0.0 'Nebula'"
git push origin v2.0.0
```

### 5. Deploy

```bash
./scripts/deploy-project.sh blogmaster production
```

### 6. Announce

```markdown
# 🚀 v2.0.0 "Nebula" Released!

We're excited to announce the release of v2.0.0 "Nebula"!

## What's New

### 🎨 Major Features
- **Real-time Collaboration**: Work together on documents in real-time
- **AI Assistant**: Integrated AI helper across the platform
- **Advanced Permissions**: Granular resource-level permissions

### 💥 Breaking Changes
- API endpoint `/api/posts` now requires authentication
- Field `author_id` renamed to `creator_id`
- See migration guide: docs/MIGRATION_V1_TO_V2.md

### 🐛 Bug Fixes
- Fixed memory leak in WebSocket connections
- Resolved timezone issues in calendar

## Upgrade Guide

...
```

---

## 📱 Version Display in UI

### Footer

```typescript
function Footer() {
  const [version, setVersion] = useState<any>(null);

  useEffect(() => {
    fetch('/api/version')
      .then(res => res.json())
      .then(setVersion);
  }, []);

  if (!version) return null;

  return (
    <footer>
      <p>
        BlogMaster {version.version} "{version.codename}"
        {version.environment !== 'production' && (
          <span> ({version.environment})</span>
        )}
      </p>
    </footer>
  );
}
```

### Changelog Modal

```typescript
function ChangelogModal() {
  const [changelog, setChangelog] = useState('');

  useEffect(() => {
    fetch('/CHANGELOG.md')
      .then(res => res.text())
      .then(setChangelog);
  }, []);

  return (
    <Modal title="What's New">
      <Markdown content={changelog} />
    </Modal>
  );
}
```

---

## 🔔 Version Notifications

### New Version Available

```typescript
// Check for updates every hour
setInterval(async () => {
  const currentVersion = VERSION.full;
  const latestVersion = await fetch('https://api.blogmaster.io/version/latest')
    .then(res => res.json());

  if (latestVersion.version !== currentVersion) {
    showNotification({
      type: 'info',
      title: 'New version available',
      message: `v${latestVersion.version} "${latestVersion.codename}" is now available. Click to see what's new.`,
      action: () => window.open('/changelog', '_blank')
    });
  }
}, 3600000); // 1 hour
```

---

## 📊 Version Analytics

```sql
-- Track which versions tenants are using
CREATE TABLE tenant_versions (
  tenant_id UUID PRIMARY KEY,
  version VARCHAR(20) NOT NULL,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Query: Version distribution
SELECT
  version,
  COUNT(*) as tenant_count,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM tenant_versions), 2) as percentage
FROM tenant_versions
GROUP BY version
ORDER BY tenant_count DESC;

-- Result:
-- version | tenant_count | percentage
-- v1.5.3  | 450          | 45.0%
-- v1.5.2  | 300          | 30.0%
-- v2.0.0  | 150          | 15.0%
-- v1.4.8  | 100          | 10.0%
```

---

## ✅ Summary

**Versioning Strategy**:
- ✅ Semantic Versioning (MAJOR.MINOR.PATCH)
- ✅ Codenames for major versions
- ✅ Changelog (Keep a Changelog format)
- ✅ API versioning (/v1, /v2)
- ✅ Git tags for releases

**Changelog Categories**:
- ✅ Added (new features)
- ✅ Changed (changes in existing)
- ✅ Deprecated (soon-to-be removed)
- ✅ Removed (removed features)
- ✅ Fixed (bug fixes)
- ✅ Security (security fixes)

**Release Process**:
1. Bump version (`npm version major/minor/patch`)
2. Generate changelog
3. Update codename (if major)
4. Create git tag
5. Deploy
6. Announce

**Version Display**:
- ✅ Footer: "BlogMaster v1.0.0 'Aurora'"
- ✅ Changelog modal
- ✅ New version notifications
- ✅ Version API endpoint

---

**Status**: Sistema di versioning completo! ✅

Ora procedo con i grandi enterprise documents! 🚀
