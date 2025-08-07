# Release Process

This document outlines the complete release process for the WuKong Easy SDK, including version management, testing, and distribution procedures.

## Version Numbering Strategy

### Semantic Versioning (SemVer)

We follow [Semantic Versioning 2.0.0](https://semver.org/) with the format `MAJOR.MINOR.PATCH`:

- **MAJOR** (X.0.0): Breaking changes that require user code modifications
- **MINOR** (0.X.0): New features that are backward compatible
- **PATCH** (0.0.X): Bug fixes and minor improvements

### Version Examples

```
1.0.0    - Initial stable release
1.0.1    - Bug fix release
1.1.0    - New feature release (backward compatible)
2.0.0    - Breaking changes release
```

### Pre-release Versions

For development and testing:
```
1.1.0-alpha.1    - Alpha release
1.1.0-beta.1     - Beta release
1.1.0-rc.1       - Release candidate
```

## Release Workflow

### 1. Planning Phase

**Release Planning Meeting**
- [ ] Define release scope and timeline
- [ ] Review feature requests and bug reports
- [ ] Assign development tasks
- [ ] Set release date target

**Documentation Requirements**
- [ ] Update API documentation for new features
- [ ] Prepare migration guides for breaking changes
- [ ] Update example applications
- [ ] Review and update README files

### 2. Development Phase

**Feature Development**
```bash
# Create feature branch
git checkout -b feature/new-feature-name
git push -u origin feature/new-feature-name

# Development work...
# Regular commits with conventional commit messages

# Create pull request when ready
```

**Code Review Process**
- [ ] All code changes reviewed by at least one maintainer
- [ ] Automated tests pass
- [ ] Documentation updated
- [ ] Breaking changes documented

### 3. Pre-Release Testing

**Automated Testing**
```bash
# Run full test suite
flutter test --coverage

# Static analysis
flutter analyze

# Format check
dart format --set-exit-if-changed .

# Example app testing
cd example
flutter test
flutter build apk --debug  # Android
flutter build ios --debug  # iOS (on macOS)
flutter build web          # Web
cd ..
```

**Manual Testing Checklist**
- [ ] Example app runs on all supported platforms
- [ ] Connection and reconnection scenarios
- [ ] Message sending and receiving
- [ ] Error handling and edge cases
- [ ] Performance under load
- [ ] Memory leak testing

**Platform Testing Matrix**

| Platform | Version | Status |
|----------|---------|--------|
| Android | 5.0+ (API 21+) | ✅ |
| iOS | 11.0+ | ✅ |
| Web | Modern browsers | ✅ |
| macOS | 10.14+ | ✅ |
| Windows | 10+ | ✅ |
| Linux | Modern distros | ✅ |

### 4. Release Preparation

**Version Update**
```bash
# Update version in pubspec.yaml
# Update version in example/pubspec.yaml if needed
# Update version references in documentation
```

**Changelog Update**
```markdown
## [1.1.0] - 2024-01-XX

### Added
- New feature: Real-time typing indicators
- Support for message reactions
- Enhanced error reporting

### Changed
- Improved reconnection algorithm
- Updated dependencies to latest versions

### Deprecated
- Old connection method (will be removed in v2.0.0)

### Removed
- Legacy callback-based API

### Fixed
- Memory leak in event listeners
- Connection timeout on slow networks

### Security
- Enhanced token validation
- Improved WebSocket security
```

**Documentation Updates**
- [ ] Update README.md with new features
- [ ] Update README.zh-CN.md (Chinese version)
- [ ] Update API documentation
- [ ] Update example code
- [ ] Review migration guides

### 5. Release Creation

**Git Tagging**
```bash
# Ensure all changes are committed
git add .
git commit -m "chore: prepare for v1.1.0 release"

# Create annotated tag
git tag -a v1.1.0 -m "Release v1.1.0

- New feature: Real-time typing indicators
- Support for message reactions
- Enhanced error reporting
- Bug fixes and performance improvements"

# Push changes and tag
git push origin main
git push origin v1.1.0
```

**GitHub Release**
1. Go to GitHub repository → Releases
2. Click "Create a new release"
3. Select tag `v1.1.0`
4. Release title: `v1.1.0 - Feature Release`
5. Copy changelog content as description
6. Mark as pre-release if applicable
7. Publish release

### 6. Package Publication

**Dry Run Validation**
```bash
# Validate package before publishing
dart pub publish --dry-run

# Check for warnings or errors
# Verify package contents
```

**Publication**
```bash
# Publish to pub.dev
dart pub publish

# Verify publication
# Check package page on pub.dev
```

### 7. Post-Release Activities

**Verification**
- [ ] Package appears on pub.dev
- [ ] Documentation renders correctly
- [ ] Installation works in test project
- [ ] All platforms can install and use the package

**Communication**
- [ ] Announce release in GitHub Discussions
- [ ] Update project documentation
- [ ] Notify dependent projects
- [ ] Social media announcement (if applicable)

**Monitoring**
- [ ] Monitor for installation issues
- [ ] Watch for bug reports
- [ ] Track download statistics
- [ ] Monitor community feedback

## Hotfix Process

For critical bugs that need immediate release:

### 1. Hotfix Branch
```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/v1.0.1

# Make minimal fix
# Test thoroughly
# Update version to 1.0.1
# Update changelog
```

### 2. Fast-Track Release
```bash
# Commit fix
git add .
git commit -m "fix: critical bug in connection handling"

# Create tag
git tag -a v1.0.1 -m "Hotfix v1.0.1 - Critical bug fix"

# Merge back to main
git checkout main
git merge hotfix/v1.0.1

# Push everything
git push origin main
git push origin v1.0.1

# Publish immediately
dart pub publish
```

## Release Schedule

### Regular Releases
- **Major releases**: Every 6-12 months
- **Minor releases**: Every 1-3 months
- **Patch releases**: As needed for bug fixes

### Release Calendar
- **Planning**: First week of month
- **Development**: Weeks 2-3
- **Testing**: Week 4
- **Release**: First week of following month

## Quality Gates

### Automated Checks
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Static analysis clean
- [ ] Code coverage > 80%
- [ ] No security vulnerabilities

### Manual Checks
- [ ] Example app works on all platforms
- [ ] Documentation is accurate
- [ ] Breaking changes are documented
- [ ] Migration guides are complete

### Performance Benchmarks
- [ ] Connection time < 2 seconds
- [ ] Message latency < 100ms
- [ ] Memory usage stable
- [ ] No memory leaks detected

## Rollback Procedures

### Immediate Rollback
```bash
# Retract problematic version (within 7 days)
dart pub retract 1.1.0

# Communicate issue to users
# Prepare fixed version
```

### Version Deprecation
```bash
# Mark version as discontinued
dart pub discontinue 1.1.0

# Provide migration path
# Update documentation
```

## Tools and Automation

### Required Tools
- Flutter SDK (latest stable)
- Dart SDK (latest stable)
- Git
- pub CLI tools

### Recommended Tools
- GitHub CLI for release automation
- Flutter/Dart IDE plugins
- Code coverage tools
- Performance profiling tools

### Future Automation
- GitHub Actions for CI/CD
- Automated testing on multiple platforms
- Automated changelog generation
- Dependency update automation

## Emergency Procedures

### Critical Security Issues
1. **Immediate Response** (within 24 hours)
   - Assess severity and impact
   - Prepare security patch
   - Coordinate with security team

2. **Patch Release** (within 48 hours)
   - Create hotfix branch
   - Implement minimal fix
   - Fast-track testing and release

3. **Communication**
   - Security advisory on GitHub
   - Update documentation
   - Notify major users directly

### Breaking Production Issues
1. **Assessment**
   - Identify affected versions
   - Determine impact scope
   - Prioritize fix development

2. **Response**
   - Retract problematic version if possible
   - Provide workaround guidance
   - Accelerate fix development

3. **Resolution**
   - Release patch version
   - Update documentation
   - Post-mortem analysis
