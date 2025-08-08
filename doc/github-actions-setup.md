# GitHub Actions Publication Setup

This guide explains how to set up automated GitHub Actions workflow for publishing the WuKong Easy SDK to pub.dev using **official Dart team best practices**.

## 🚀 Workflow Overview

The GitHub Actions workflow uses the **official reusable workflow** maintained by the Dart team, ensuring reliability and following all best practices.

### Features
- ✅ **Official Dart team workflow** - maintained and tested by experts
- ✅ **OIDC authentication** - secure temporary tokens, no long-term secrets
- ✅ **Automatic triggering** on version tag pushes only (as required by pub.dev)
- ✅ **Built-in validation** - analysis, tests, and package structure checks
- ✅ **Simple configuration** - minimal setup required
- ✅ **Enhanced security** - no manual token management needed

## 🔧 Setup Instructions

### 1. Configure Automated Publishing on pub.dev

**This is the most important step that must be completed first.**

**Step 1: Verify Package Permissions**
You must be either:
- An uploader of the package, or
- An admin of the publisher (if the package belongs to a publisher)

**Step 2: Enable Automated Publishing**
1. Navigate to the **Admin tab** at `pub.dev/packages/wukong_easy_sdk/admin`
2. Find the **Automated publishing** section
3. Click **Enable publishing from GitHub Actions**
4. Configure the following:
   - **Repository**: `WuKongIM/WuKongEasySDK-Flutter` (your GitHub repository)
   - **Tag pattern**: `v{{version}}` (allows tags like v1.0.0, v1.2.3, etc.)

**Step 3: Verify Configuration**
- The repository field should match your GitHub repository exactly
- The tag pattern `v{{version}}` means only tags like `v1.0.0` will trigger publishing
- The version in your `pubspec.yaml` must match the tag version (without the 'v' prefix)

### 2. Verify Workflow File

Ensure the workflow file is present at `.github/workflows/publish.yml`. The file should use the official reusable workflow:

```yaml
name: 📦 Publish to pub.dev

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+*'  # Matches v1.0.0, v1.2.3, etc.

jobs:
  publish:
    permissions:
      id-token: write # Required for OIDC authentication
    uses: dart-lang/setup-dart/.github/workflows/publish.yml@v1
```

**No secrets or tokens needed!** The workflow uses secure OIDC authentication.

## 📋 Usage Instructions

### Publishing a New Version

**Step 1: Update Version in pubspec.yaml**
```yaml
name: wukong_easy_sdk
version: 1.0.1  # Update this version number
```

**Step 2: Update CHANGELOG.md**
```markdown
## [1.0.1] - 2024-01-XX

### Added
- New features...

### Fixed
- Bug fixes...
```

**Step 3: Commit Changes**
```bash
git add .
git commit -m "chore: prepare for v1.0.1 release"
git push origin main
```

**Step 4: Create and Push Tag**
```bash
# Create annotated tag (must match the pattern configured on pub.dev)
git tag -a v1.0.1 -m "Release v1.0.1

- New features and improvements
- Bug fixes and optimizations"

# Push tag to trigger automatic publishing
git push origin v1.0.1
```

**Step 5: Monitor Publication**
1. Go to **Actions** tab in GitHub repository
2. Watch the "📦 Publish to pub.dev" workflow execution
3. Verify successful completion
4. Check that the package appears on pub.dev

**Important Notes:**
- ✅ The tag version (v1.0.1) must match the pubspec.yaml version (1.0.1)
- ✅ Only tag pushes trigger publication (manual workflow dispatch is not supported by pub.dev)
- ✅ The tag pattern must match what you configured on pub.dev (v{{version}})

## 🔍 Workflow Stages

### Stage 1: Pre-publication Validation
```yaml
Jobs:
  - 🔍 Static Analysis (dart analyze)
  - 🧪 Unit Tests (flutter test)
  - 🏗️ Example App Build
  - 📋 Package Structure Validation
```

### Stage 2: Publication
```yaml
Jobs:
  - 🔐 Pub.dev Authentication
  - 🏷️ Version Extraction and Validation
  - 🚀 Package Publication
  - 🔗 GitHub Release Creation
```

### Stage 3: Notification
```yaml
Jobs:
  - 📢 Status Reporting
  - 📊 Success/Failure Notification
```

## ⚠️ Troubleshooting

### Common Issues

**1. Authentication Failed**
```
Error: Authentication failed
```
**Solution**: Verify `PUB_TOKEN` secret is correctly set with valid pub.dev token.

**2. Version Mismatch**
```
Error: Version mismatch between pubspec.yaml and git tag
```
**Solution**: Ensure version in `pubspec.yaml` matches the git tag (without 'v' prefix).

**3. Validation Failed**
```
Error: Static analysis failed
```
**Solution**: Fix code issues locally and ensure `dart analyze` passes before tagging.

**4. Package Already Published**
```
Error: Version already exists on pub.dev
```
**Solution**: Increment version number in `pubspec.yaml` and create new tag.

### Debug Steps

**1. Check Workflow Logs**
```bash
# Navigate to Actions tab in GitHub
# Click on failed workflow run
# Expand failed job steps to see detailed logs
```

**2. Local Validation**
```bash
# Run the same checks locally
dart analyze
flutter test
dart pub publish --dry-run
```

**3. Verify Secrets**
```bash
# Ensure PUB_TOKEN secret is set correctly
# Check token hasn't expired
```

## 🔒 Security Best Practices

### Token Management
- ✅ **Never commit tokens** to repository
- ✅ **Use GitHub Secrets** for sensitive data
- ✅ **Rotate tokens periodically** for security
- ✅ **Limit token scope** to publication only

### Workflow Security
- ✅ **Branch protection** on main branch
- ✅ **Required reviews** for workflow changes
- ✅ **Audit workflow runs** regularly
- ✅ **Monitor publication logs** for anomalies

## 📊 Monitoring and Maintenance

### Regular Checks
- **Monthly**: Verify workflow still functions correctly
- **Quarterly**: Update Flutter/Dart versions in workflow
- **Annually**: Rotate pub.dev authentication tokens

### Workflow Updates
```yaml
# Update Flutter version
env:
  FLUTTER_VERSION: '3.19.x'  # Update to latest stable
  DART_VERSION: '3.3.x'     # Update corresponding Dart version
```

### Success Indicators
- ✅ Workflow completes without errors
- ✅ Package appears on pub.dev within 5 minutes
- ✅ GitHub release is created automatically
- ✅ All validation steps pass

## 🎯 Best Practices

### Release Preparation
1. **Test thoroughly** on multiple platforms
2. **Update documentation** before release
3. **Verify example app** works correctly
4. **Review changelog** for completeness
5. **Check dependency versions** are current

### Version Management
```bash
# Follow semantic versioning
v1.0.0  # Major release
v1.1.0  # Minor release (new features)
v1.0.1  # Patch release (bug fixes)
```

### Communication
- **Announce releases** in project discussions
- **Update README** with latest version
- **Notify users** of breaking changes
- **Provide migration guides** when needed

## 📞 Support

### Getting Help
- **Workflow Issues**: Check GitHub Actions documentation
- **Pub.dev Issues**: Consult pub.dev publishing guide
- **Package Issues**: Create issue in repository
- **General Questions**: Use GitHub Discussions

### Resources
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Flutter Package Development](https://docs.flutter.dev/development/packages-and-plugins/developing-packages)
- [Semantic Versioning](https://semver.org/)

This automated workflow ensures reliable, secure, and efficient publication of the WuKong Easy SDK to pub.dev! 🚀
