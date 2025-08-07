# Publishing Guide

This guide provides step-by-step instructions for publishing the WuKong Easy SDK to pub.dev.

## Prerequisites

### 1. Pub.dev Account Setup

1. **Create Account**: Visit [pub.dev](https://pub.dev) and sign in with your Google account
2. **Verify Email**: Ensure your email is verified in your Google account
3. **Publisher Setup**: Optionally create a verified publisher for professional packages

### 2. Authentication Setup

```bash
# Install or update pub CLI
dart pub global activate pub_api

# Login to pub.dev (this will open a browser)
dart pub login
```

Verify authentication:
```bash
dart pub token list
```

## Pre-Publication Checklist

### 1. Version Management

Update version in `pubspec.yaml`:
```yaml
name: wukong_easy_sdk
description: A lightweight Flutter SDK for WuKongIM that enables real-time chat functionality in 5 minutes.
version: 1.0.0  # Update this version
```

### 2. Changelog Update

Update `CHANGELOG.md` with new version:
```markdown
## [1.0.0] - 2024-01-XX

### Added
- Initial release features...

### Changed
- Breaking changes...

### Fixed
- Bug fixes...
```

### 3. Documentation Verification

- [ ] README.md is comprehensive and up-to-date
- [ ] README.zh-CN.md matches English version
- [ ] API documentation is complete
- [ ] Example application works correctly
- [ ] All code examples in documentation are tested

### 4. Code Quality Checks

```bash
# Run static analysis
flutter analyze

# Run all tests
flutter test

# Check formatting
dart format --set-exit-if-changed .

# Verify example app
cd example
flutter analyze
flutter test
cd ..
```

### 5. Package Validation

```bash
# Validate package structure
dart pub publish --dry-run
```

This command will:
- Check package structure
- Validate pubspec.yaml
- Verify all required files are present
- Check for common issues

## Publication Process

### Step 1: Final Validation

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Run comprehensive tests
flutter test --coverage

# Validate package one more time
dart pub publish --dry-run
```

### Step 2: Create Git Tag

```bash
# Ensure all changes are committed
git add .
git commit -m "chore: prepare for v1.0.0 release"

# Create and push tag
git tag v1.0.0
git push origin main
git push origin v1.0.0
```

### Step 3: Publish to Pub.dev

```bash
# Publish the package
dart pub publish
```

You'll be prompted to:
1. Review package contents
2. Confirm publication
3. Type 'y' to proceed

### Step 4: Verify Publication

1. **Check pub.dev**: Visit `https://pub.dev/packages/wukong_easy_sdk`
2. **Verify version**: Ensure the new version is listed
3. **Test installation**: Try installing in a test project:

```bash
# Create test project
flutter create test_wukong
cd test_wukong

# Add dependency
flutter pub add wukong_easy_sdk

# Verify it works
flutter pub get
```

## Post-Publication Steps

### 1. Update Documentation

- [ ] Update README badges if needed
- [ ] Verify documentation renders correctly on pub.dev
- [ ] Update any external documentation links

### 2. Create GitHub Release

1. Go to GitHub repository
2. Click "Releases" → "Create a new release"
3. Use tag `v1.0.0`
4. Copy changelog content as release notes
5. Attach any additional assets if needed

### 3. Announce Release

- [ ] Update project README with latest version
- [ ] Notify team/community about the release
- [ ] Update any dependent projects

## Troubleshooting

### Common Issues

**1. Authentication Problems**
```bash
# Clear and re-authenticate
dart pub logout
dart pub login
```

**2. Package Validation Errors**
- Check pubspec.yaml format
- Ensure all required fields are present
- Verify file structure matches pub.dev requirements

**3. Version Conflicts**
- Ensure version number is higher than previous
- Check for pre-release versions if needed
- Verify semantic versioning compliance

**4. Documentation Issues**
- Ensure README.md is present and comprehensive
- Check that all links work correctly
- Verify code examples are accurate

### Getting Help

- **Pub.dev Help**: https://dart.dev/tools/pub/publishing
- **Flutter Documentation**: https://docs.flutter.dev/development/packages-and-plugins/developing-packages
- **Community Support**: https://github.com/WuKongIM/wukong_easy_sdk/discussions

## Security Considerations

### 1. Sensitive Information

- [ ] No API keys or secrets in code
- [ ] No personal information in examples
- [ ] Proper .gitignore for sensitive files

### 2. Dependencies

- [ ] All dependencies are from trusted sources
- [ ] No known security vulnerabilities
- [ ] Regular dependency updates planned

### 3. Code Review

- [ ] All code has been reviewed
- [ ] No malicious or suspicious code
- [ ] Proper error handling implemented

## Rollback Procedure

If issues are discovered after publication:

1. **Immediate Response**:
   ```bash
   # Retract the problematic version (within 7 days)
   dart pub retract <version>
   ```

2. **Fix and Re-release**:
   - Fix the issue in code
   - Increment version number
   - Follow publication process again

3. **Communication**:
   - Update changelog with fix details
   - Notify users through GitHub issues/discussions
   - Update documentation if needed

## Automation (Future Enhancement)

Consider setting up GitHub Actions for automated publishing:

```yaml
# .github/workflows/publish.yml
name: Publish to pub.dev
on:
  push:
    tags:
      - 'v*'
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart pub publish --force
        env:
          PUB_TOKEN: ${{ secrets.PUB_TOKEN }}
```

This enables automatic publishing when tags are pushed to the repository.
