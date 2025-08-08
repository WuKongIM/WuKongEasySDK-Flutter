# GitHub Actions 发布设置

本指南说明如何使用 **Dart 官方团队最佳实践** 设置自动化 GitHub Actions 工作流来将 WuKong Easy SDK 发布到 pub.dev。

## 🚀 工作流概述

GitHub Actions 工作流使用 **Dart 团队维护的官方可复用工作流**，确保可靠性并遵循所有最佳实践。

### 功能特性
- ✅ **官方 Dart 团队工作流** - 由专家维护和测试
- ✅ **OIDC 认证** - 安全的临时令牌，无需长期密钥
- ✅ **自动触发** 仅在版本标签推送时（pub.dev 要求）
- ✅ **内置验证** - 分析、测试和包结构检查
- ✅ **简单配置** - 最少的设置要求
- ✅ **增强安全性** - 无需手动令牌管理

## 🔧 设置说明

### 1. 在 pub.dev 上配置自动化发布

**这是必须首先完成的最重要步骤。**

**步骤 1: 验证包权限**
您必须是以下之一：
- 包的上传者，或
- 发布者的管理员（如果包属于发布者）

**步骤 2: 启用自动化发布**
1. 导航到 **管理选项卡** `pub.dev/packages/wukong_easy_sdk/admin`
2. 找到 **自动化发布** 部分
3. 点击 **启用从 GitHub Actions 发布**
4. 配置以下内容：
   - **仓库**: `WuKongIM/WuKongEasySDK-Flutter`（您的 GitHub 仓库）
   - **标签模式**: `v{{version}}`（允许 v1.0.0、v1.2.3 等标签）

**步骤 3: 验证配置**
- 仓库字段应完全匹配您的 GitHub 仓库
- 标签模式 `v{{version}}` 意味着只有像 `v1.0.0` 这样的标签才会触发发布
- 您的 `pubspec.yaml` 中的版本必须与标签版本匹配（不带 'v' 前缀）

### 2. 验证工作流文件

确保工作流文件存在于 `.github/workflows/publish.yml`。文件应使用官方可复用工作流：

```yaml
name: 📦 Publish to pub.dev

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+*'  # 匹配 v1.0.0、v1.2.3 等

jobs:
  publish:
    permissions:
      id-token: write # OIDC 认证所需
    uses: dart-lang/setup-dart/.github/workflows/publish.yml@v1
```

**无需密钥或令牌！** 工作流使用安全的 OIDC 认证。

## 📋 使用说明

### 自动发布（推荐）

**步骤 1: 更新版本**
```bash
# 在 pubspec.yaml 中更新版本
version: 1.0.1

# 在 CHANGELOG.md 中更新新版本详情
```

**步骤 2: 提交更改**
```bash
git add .
git commit -m "chore: prepare for v1.0.1 release"
git push origin main
```

**步骤 3: 创建并推送标签**
```bash
# 创建带注释的标签
git tag -a v1.0.1 -m "Release v1.0.1

- 新功能和改进
- 错误修复和优化"

# 推送标签以触发工作流
git push origin v1.0.1
```

**步骤 4: 监控工作流**
1. 转到 GitHub 仓库中的 **Actions** 选项卡
2. 观察 "📦 Publish to pub.dev" 工作流
3. 验证成功完成

### 手动发布

**步骤 1: 导航到 Actions**
1. 转到 GitHub 仓库中的 **Actions** 选项卡
2. 点击 "📦 Publish to pub.dev" 工作流
3. 点击 **Run workflow**

**步骤 2: 指定版本**
1. 输入版本（例如，`v1.0.1`）
2. 点击 **Run workflow**

**步骤 3: 监控执行**
观察工作流进度并验证完成。

## 🔍 工作流阶段

### 阶段 1: 发布前验证
```yaml
作业:
  - 🔍 静态分析 (dart analyze)
  - 🧪 单元测试 (flutter test)
  - 🏗️ 示例应用构建
  - 📋 包结构验证
```

### 阶段 2: 发布
```yaml
作业:
  - 🔐 Pub.dev 认证
  - 🏷️ 版本提取和验证
  - 🚀 包发布
  - 🔗 GitHub 发布创建
```

### 阶段 3: 通知
```yaml
作业:
  - 📢 状态报告
  - 📊 成功/失败通知
```

## ⚠️ 故障排除

### 常见问题

**1. 认证失败**
```
错误: Authentication failed
```
**解决方案**: 验证 `PUB_TOKEN` 密钥是否正确设置了有效的 pub.dev 令牌。

**2. 版本不匹配**
```
错误: Version mismatch between pubspec.yaml and git tag
```
**解决方案**: 确保 `pubspec.yaml` 中的版本与 git 标签匹配（不带 'v' 前缀）。

**3. 验证失败**
```
错误: Static analysis failed
```
**解决方案**: 在本地修复代码问题，确保 `dart analyze` 在标记前通过。

**4. 包已发布**
```
错误: Version already exists on pub.dev
```
**解决方案**: 在 `pubspec.yaml` 中增加版本号并创建新标签。

### 调试步骤

**1. 检查工作流日志**
```bash
# 导航到 GitHub 中的 Actions 选项卡
# 点击失败的工作流运行
# 展开失败的作业步骤以查看详细日志
```

**2. 本地验证**
```bash
# 在本地运行相同的检查
dart analyze
flutter test
dart pub publish --dry-run
```

**3. 验证密钥**
```bash
# 确保 PUB_TOKEN 密钥设置正确
# 检查令牌是否未过期
```

## 🔒 安全最佳实践

### 令牌管理
- ✅ **永不提交令牌** 到仓库
- ✅ **使用 GitHub Secrets** 存储敏感数据
- ✅ **定期轮换令牌** 以确保安全
- ✅ **限制令牌范围** 仅用于发布

### 工作流安全
- ✅ **主分支保护** 
- ✅ **工作流更改需要审查**
- ✅ **定期审计工作流运行**
- ✅ **监控发布日志** 异常情况

## 📊 监控和维护

### 定期检查
- **每月**: 验证工作流仍正常运行
- **每季度**: 更新工作流中的 Flutter/Dart 版本
- **每年**: 轮换 pub.dev 认证令牌

### 工作流更新
```yaml
# 更新 Flutter 版本
env:
  FLUTTER_VERSION: '3.19.x'  # 更新到最新稳定版
  DART_VERSION: '3.3.x'     # 更新对应的 Dart 版本
```

### 成功指标
- ✅ 工作流无错误完成
- ✅ 包在 5 分钟内出现在 pub.dev 上
- ✅ 自动创建 GitHub 发布
- ✅ 所有验证步骤通过

## 🎯 最佳实践

### 发布准备
1. **在多个平台上彻底测试**
2. **发布前更新文档**
3. **验证示例应用** 正常工作
4. **审查更新日志** 完整性
5. **检查依赖版本** 是否最新

### 版本管理
```bash
# 遵循语义版本控制
v1.0.0  # 主要发布
v1.1.0  # 次要发布（新功能）
v1.0.1  # 补丁发布（错误修复）
```

### 沟通
- **在项目讨论中宣布发布**
- **使用最新版本更新 README**
- **通知用户** 破坏性变更
- **在需要时提供迁移指南**

## 📞 支持

### 获取帮助
- **工作流问题**: 查看 GitHub Actions 文档
- **Pub.dev 问题**: 咨询 pub.dev 发布指南
- **包问题**: 在仓库中创建问题
- **一般问题**: 使用 GitHub Discussions

### 资源
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Pub.dev 发布指南](https://dart.dev/tools/pub/publishing)
- [Flutter 包开发](https://docs.flutter.dev/development/packages-and-plugins/developing-packages)
- [语义版本控制](https://semver.org/)

这个自动化工作流确保了 WuKong Easy SDK 到 pub.dev 的可靠、安全和高效发布！🚀
